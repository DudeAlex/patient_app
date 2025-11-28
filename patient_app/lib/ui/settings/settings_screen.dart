import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:google_drive_backup/google_drive_backup.dart';
import 'package:intl/intl.dart';

import '../../core/ai/ai_config.dart';
import '../../core/ai/repositories/ai_config_repository.dart';
import '../../core/ai/repositories/ai_consent_repository.dart';
import '../../core/ai/chat/repositories/context_config_repository.dart';
import '../../core/di/app_container.dart';
import '../../features/information_items/ui/widgets/ai_consent_dialog.dart';
import '../../features/records/data/records_service.dart';
import '../../features/sync/application/use_cases/mark_auto_sync_success_use_case.dart';
import '../../features/sync/application/use_cases/set_auto_sync_cadence_use_case.dart';
import '../../features/sync/application/use_cases/set_auto_sync_enabled_use_case.dart';
import '../../features/sync/auto_sync_backup_service.dart';
import '../../features/sync/domain/entities/auto_sync_cadence.dart';
import '../../features/sync/domain/entities/auto_sync_status.dart';
import '../screens/ai_diagnostics_screen.dart';
import '../screens/design_showcase_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AutoSyncBackupService _backupService = AutoSyncBackupService();
  DriveBackupManager get _manager => _backupService.manager;
  late final AiConfigRepository _aiConfigRepository =
      AppContainer.instance.resolve<AiConfigRepository>();
  late final AiConsentRepository _aiConsentRepository =
      AppContainer.instance.resolve<AiConsentRepository>();
  late final ContextConfigRepository _contextConfigRepository =
      AppContainer.instance.resolve<ContextConfigRepository>();

  String? _email;
  bool _busy = false;
  RecordsService? _recordsService;
  StreamSubscription<AutoSyncStatus>? _autoSyncSubscription;
  AutoSyncStatus? _autoSyncStatus;
  bool _autoSyncBusy = false;
  bool _autoSyncInitialised = false;

  AutoSyncCadenceOption _selectedCadence = AutoSyncCadenceOption.weekly;
  bool _cadenceBusy = false;
  ThemeModePreference _themePreference = ThemeModePreference.system;
  TextScalePreference _textPreference = TextScalePreference.medium;
  bool _aiFeaturesEnabled = false;
  AiMode _aiMode = AiMode.fake;
  bool _aiConfigBusy = false;
  bool _aiConsentEnabled = false;
  bool _aiConsentBusy = false;
  int _dateRangeDays = 14;
  bool _dateRangeBusy = false;

  @override
  void initState() {
    super.initState();
    _restoreAccount();
    if (!kIsWeb) {
      _initAutoSync();
    }
    _loadAiConfig();
    _loadAiConsent();
    _loadContextConfig();
  }

  @override
  void dispose() {
    _autoSyncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _restoreAccount() async {
    final cached = _manager.auth.cachedEmail;
    if (cached != null) {
      setState(() => _email = cached);
    }
    final email = await _manager.restoreAccount();
    if (!mounted) return;
    setState(() => _email = email ?? cached);
    final effectiveEmail = email ?? cached;
    if (effectiveEmail != null) {
      Future.microtask(
        () => _manager.auth.getAuthHeaders(promptIfNecessary: false),
      );
    }
  }

  Future<void> _loadAiConfig() async {
    try {
      final config = await _aiConfigRepository.loadConfig();
      if (!mounted) return;
      setState(() {
        _aiFeaturesEnabled = config.enabled;
        _aiMode = config.mode;
      });
    } catch (e) {
      debugPrint('[Settings] Failed to load AI config: $e');
    }
  }

  Future<void> _loadAiConsent() async {
    try {
      final granted = await _aiConsentRepository.hasConsent();
      if (!mounted) return;
      setState(() => _aiConsentEnabled = granted);
    } catch (e) {
      debugPrint('[Settings] Failed to load AI consent: $e');
    }
  }

  Future<void> _loadContextConfig() async {
    try {
      final days = await _contextConfigRepository.getDateRangeDays();
      if (!mounted) return;
      setState(() => _dateRangeDays = days);
    } catch (e) {
      debugPrint('[Settings] Failed to load context config: $e');
    }
  }

  Future<void> _updateDateRange(int days) async {
    setState(() => _dateRangeBusy = true);
    try {
      await _contextConfigRepository.setDateRangeDays(days);
      if (!mounted) return;
      setState(() => _dateRangeDays = days);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Context date range set to $days days'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update date range: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _dateRangeBusy = false);
      }
    }
  }

  Future<void> _initAutoSync() async {
    try {
      final service = await RecordsService.instance();
      if (!mounted) return;
      final initialStatus =
          service.autoSync.latestStatus ??
          await service.readAutoSyncStatus.execute();
      setState(() {
        _recordsService = service;
        _backupService = service.backupService;
        _autoSyncStatus = initialStatus;
        _selectedCadence =
            AutoSyncCadenceOption.fromCadence(initialStatus.cadence);
        _autoSyncInitialised = true;
      });
      _autoSyncSubscription = service.autoSync.statusStream.listen((
        AutoSyncStatus status,
      ) {
        if (!mounted) return;
        setState(() {
          _autoSyncStatus = status;
          _selectedCadence =
              AutoSyncCadenceOption.fromCadence(status.cadence);
        });
      });
      // Refresh cached email with the shared Drive manager.
      _restoreAccount();
    } catch (e, st) {
      debugPrint('[Settings] Failed to initialise auto sync: $e');
      debugPrint('[Settings] STACK: ${st.toString().split('\n').first}');
      if (!mounted) return;
      setState(() => _autoSyncInitialised = true);
    }
  }

  Future<void> _toggleAutoSync(bool value) async {
    final service = _recordsService;
    if (service == null) return;
    setState(() => _autoSyncBusy = true);
    try {
      await service.setAutoSyncEnabled.execute(
        SetAutoSyncEnabledInput(enabled: value),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update auto backup: $e')),
      );
    } finally {
      if (mounted) setState(() => _autoSyncBusy = false);
    }
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final acc = await _manager.auth.signIn();
      final email = await _manager.restoreAccount();
      setState(() => _email = email);
      if (email == null || acc == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in cancelled or failed. Check logs.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Signed in as $email')));
        }
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await _manager.auth.signOut();
      setState(() => _email = null);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _backupToDrive() async {
    if (_email == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Uploading backup to Drive...')),
      );
      final result = await _backupService.runBackup(promptIfNecessary: true);
      messenger.hideCurrentSnackBar();
      if (result.isSuccess) {
        final completedAt = result.completedAt ?? DateTime.now();
        final service = _recordsService;
        if (service != null) {
          await service.markAutoSyncSuccess.execute(
            MarkAutoSyncSuccessInput(completedAt: completedAt),
          );
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text('Backup uploaded (${_formatTimestamp(completedAt)})'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Backup failed. Please try again.\n${result.error}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed unexpectedly: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromDrive() async {
    if (_email == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      try {
        await _manager.restoreFromDrive();
      } on StateError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restoring backup...')));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restore completed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _runAuthDiagnostics() async {
    setState(() => _busy = true);
    try {
      final s = await _manager.auth.diagnostics();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Auth Diagnostics'),
          content: SingleChildScrollView(child: Text(s)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final formatter = DateFormat.yMMMd().add_jm();
    return formatter.format(timestamp);
  }

  String _formatLastSynced(DateTime? timestamp) {
    if (timestamp == null) return 'Last sync: never';
    return 'Last sync: ${_formatTimestamp(timestamp)}';
  }

  String _pendingSummary(AutoSyncStatus status) {
    return 'Pending changes - critical: ${status.pendingCriticalChanges}, routine: ${status.pendingRoutineChanges}';
  }

  Future<void> _updateCadence(AutoSyncCadenceOption option) async {
    final service = _recordsService;
    if (service == null) return;
    setState(() {
      _selectedCadence = option;
      _cadenceBusy = true;
    });
    try {
      await service.setAutoSyncCadence.execute(
        SetAutoSyncCadenceInput(cadence: option.cadence),
      );
      if (!mounted) return;
      final message = option.cadence.isManual
          ? 'Automatic backups disabled. Manual backups only.'
          : 'Auto backup cadence set to ${option.label}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update cadence: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _cadenceBusy = false);
      }
    }
  }

  Future<void> _toggleAiConsent(bool value) async {
    if (!_aiFeaturesEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable AI assistance before giving consent.')),
      );
      return;
    }
    if (value) {
      final accepted = await showAiConsentDialog(context);
      if (!mounted || !accepted) return;
      await _updateAiConsent(() => _aiConsentRepository.grantConsent(), true);
      return;
    }
    await _updateAiConsent(() => _aiConsentRepository.revokeConsent(), false);
  }

  void _viewAiDiagnostics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const riverpod.ProviderScope(
          child: AiDiagnosticsScreen(),
        ),
      ),
    );
  }

  Future<void> _updateAiFeatures(bool value) async {
    setState(() => _aiConfigBusy = true);
    try {
      await _aiConfigRepository.setEnabled(value);
      if (!mounted) return;
      setState(() => _aiFeaturesEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'AI features enabled. Summaries appear on detail screens.'
                : 'AI features disabled.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update AI settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _aiConfigBusy = false);
    }
  }

  Future<void> _updateAiMode(AiMode mode) async {
    if (!_aiFeaturesEnabled || mode == _aiMode) return;
    setState(() => _aiConfigBusy = true);
    try {
      await _aiConfigRepository.setMode(mode);
      if (!mounted) return;
      setState(() => _aiMode = mode);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update AI mode: $e')),
      );
    } finally {
      if (mounted) setState(() => _aiConfigBusy = false);
    }
  }

  Future<void> _updateAiConsent(
    Future<void> Function() action,
    bool enabled,
  ) async {
    setState(() => _aiConsentBusy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() => _aiConsentEnabled = enabled);
      final message = enabled
          ? 'AI assistance enabled. You can disable it anytime.'
          : 'AI assistance disabled.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update AI consent: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _aiConsentBusy = false);
      }
    }
  }

  void _showBackupKeyDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup key portability'),
        content: const Text(
          'A secure export/import experience (passphrase, QR, or platform key '
          'backup) is in flight. Keep this device nearby when restoring until it ships.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateTheme(ThemeModePreference preference) {
    setState(() => _themePreference = preference);
  }

  void _updateTextScale(TextScalePreference preference) {
    setState(() => _textPreference = preference);
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final status = _autoSyncStatus;
    final autoSyncEnabled = status?.autoSyncEnabled ?? false;
    final showAutoSync = !isWeb;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHubCard(
              email: _email,
              isWeb: isWeb,
              onSignIn: _signIn,
              onSignOut: _signOut,
              onBackupNow: isWeb ? null : _backupToDrive,
              lastSyncLabel: _formatLastSynced(status?.lastSyncedAt),
              pendingSummary: status != null
                  ? _pendingSummary(status)
                  : 'Pending change info unavailable.',
              autoSyncToggle: showAutoSync
                  ? AutoSyncToggleData(
                      enabled: autoSyncEnabled,
                      busy: _autoSyncBusy,
                      initialised: _autoSyncInitialised,
                      onToggle: _toggleAutoSync,
                    )
                  : null,
              cadenceOptions: _cadenceOptions,
              selectedCadence: _selectedCadence,
              onSelectCadence:
                  _autoSyncInitialised && !_cadenceBusy ? _updateCadence : null,
            ),
            const SizedBox(height: 16),
            if (!isWeb)
              _DisplayPreferencesCard(
                themePreference: _themePreference,
                textPreference: _textPreference,
                onThemeChanged: _updateTheme,
                onTextChanged: _updateTextScale,
              ),
            if (!isWeb) const SizedBox(height: 16),
            _AiSettingsCard(
              enabled: _aiFeaturesEnabled,
              mode: _aiMode,
              busy: _aiConfigBusy,
              onEnabledChanged: _updateAiFeatures,
              onModeChanged: _updateAiMode,
            ),
            const SizedBox(height: 16),
            _AiConsentCard(
              enabled: _aiConsentEnabled,
               available: _aiFeaturesEnabled,
              busy: _aiConsentBusy,
              onChanged: _toggleAiConsent,
            ),
            const SizedBox(height: 16),
            _ContextSettingsCard(
              dateRangeDays: _dateRangeDays,
              busy: _dateRangeBusy,
              onDateRangeChanged: _updateDateRange,
            ),
            const SizedBox(height: 16),
            if (!isWeb) _BackupKeyCard(onManageKeys: _showBackupKeyDialog),
            if (!isWeb) const SizedBox(height: 16),
            _DiagnosticsCard(
              isWeb: isWeb,
              onBackup: isWeb ? null : _backupToDrive,
              onRestore: isWeb ? null : _restoreFromDrive,
              onAuthDiagnostics: _runAuthDiagnostics,
              onViewAiCalls: _viewAiDiagnostics,
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHubCard extends StatelessWidget {
  const _ProfileHubCard({
    required this.email,
    required this.isWeb,
    required this.onSignIn,
    required this.onSignOut,
    required this.onBackupNow,
    required this.lastSyncLabel,
    required this.pendingSummary,
    required this.cadenceOptions,
    required this.selectedCadence,
    required this.onSelectCadence,
    this.autoSyncToggle,
  });

  final String? email;
  final bool isWeb;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback? onBackupNow;
  final String lastSyncLabel;
  final String pendingSummary;
  final AutoSyncToggleData? autoSyncToggle;
  final List<AutoSyncCadenceOption> cadenceOptions;
  final AutoSyncCadenceOption selectedCadence;
  final ValueChanged<AutoSyncCadenceOption>? onSelectCadence;

  @override
  Widget build(BuildContext context) {
    final signedIn = email != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile & Backup',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(signedIn ? 'Signed in: $email' : 'Not signed in'),
                ),
                OutlinedButton(
                  onPressed: signedIn ? onSignOut : onSignIn,
                  child: Text(signedIn ? 'Sign out' : 'Sign in'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(lastSyncLabel),
            const SizedBox(height: 4),
            Text(pendingSummary, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onBackupNow,
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Backup now'),
            ),
            if (isWeb)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Drive backups are disabled on the web build because browsers cannot access the local app data directory.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            if (autoSyncToggle != null) ...[
              const Divider(height: 24),
              SwitchListTile.adaptive(
                title: const Text('Auto backup (beta)'),
                subtitle: Text(
                  autoSyncToggle!.initialised
                      ? 'Automatically backs up after important changes when enabled.'
                      : 'Checking auto backup status.',
                ),
                value: autoSyncToggle!.enabled,
                onChanged:
                    (!autoSyncToggle!.busy && autoSyncToggle!.initialised)
                    ? autoSyncToggle!.onToggle
                    : null,
                secondary: autoSyncToggle!.busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
              ),
              const SizedBox(height: 8),
              Text(
                'Cadence presets',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Wrap(
                spacing: 8,
                children: cadenceOptions
                    .map(
                      (option) => ChoiceChip(
                        label: Text(option.label),
                        selected: selectedCadence == option,
                        onSelected: onSelectCadence == null
                            ? null
                            : (_) => onSelectCadence!(option),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manual disables automatic backups. Other presets define the minimum interval between background runs while on Wi-Fi.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AutoSyncToggleData {
  const AutoSyncToggleData({
    required this.enabled,
    required this.busy,
    required this.initialised,
    required this.onToggle,
  });

  final bool enabled;
  final bool busy;
  final bool initialised;
  final ValueChanged<bool> onToggle;
}

class _DisplayPreferencesCard extends StatelessWidget {
  const _DisplayPreferencesCard({
    required this.themePreference,
    required this.textPreference,
    required this.onThemeChanged,
    required this.onTextChanged,
  });

  final ThemeModePreference themePreference;
  final TextScalePreference textPreference;
  final ValueChanged<ThemeModePreference> onThemeChanged;
  final ValueChanged<TextScalePreference> onTextChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display preferences',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Theme', style: Theme.of(context).textTheme.bodySmall),
            Wrap(
              spacing: 8,
              children: ThemeModePreference.values
                  .map(
                    (pref) => ChoiceChip(
                      label: Text(pref.label),
                      selected: themePreference == pref,
                      onSelected: (_) => onThemeChanged(pref),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text('Text size', style: Theme.of(context).textTheme.bodySmall),
            Wrap(
              spacing: 8,
              children: TextScalePreference.values
                  .map(
                    (pref) => ChoiceChip(
                      label: Text(pref.label),
                      selected: textPreference == pref,
                      onSelected: (_) => onTextChanged(pref),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            const Text(
              'Theme/text options currently apply to Patient App screens only. Global overrides will follow.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSettingsCard extends StatelessWidget {
  const _AiSettingsCard({
    required this.enabled,
    required this.mode,
    required this.onEnabledChanged,
    required this.onModeChanged,
    this.busy = false,
  });

  final bool enabled;
  final AiMode mode;
  final bool busy;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<AiMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('AI features'),
              subtitle: const Text(
                'Controls whether summaries appear throughout the app.',
              ),
              value: enabled,
              onChanged: busy ? null : onEnabledChanged,
            ),
            const SizedBox(height: 12),
            Text(
              'Mode',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AiMode.values.map((option) {
                final selected = option == mode;
                return ChoiceChip(
                  label: Text(option.label),
                  selected: selected,
                  onSelected: (!enabled || busy)
                      ? null
                      : (_) => onModeChanged(option),
                );
              }).toList(),
            ),
            if (!enabled)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Enable AI to pick between Fake (offline demo) or Remote (backend).',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _AiConsentCard extends StatelessWidget {
  const _AiConsentCard({
    required this.enabled,
    required this.available,
    required this.onChanged,
    this.busy = false,
  });

  final bool enabled;
  final bool available;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final subtitle = available
        ? 'Allow summaries across Spaces. Per-request banners explain each AI call.'
        : 'Enable AI features to grant consent.';
    return Card(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            title: const Text('AI companion consent'),
            subtitle: Text(subtitle),
            value: enabled && available,
            onChanged: (!available || busy) ? null : onChanged,
            secondary: const Icon(Icons.psychology_alt_outlined),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _ContextSettingsCard extends StatelessWidget {
  const _ContextSettingsCard({
    required this.dateRangeDays,
    required this.onDateRangeChanged,
    this.busy = false,
  });

  final int dateRangeDays;
  final bool busy;
  final ValueChanged<int> onDateRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Context Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Controls how much historical data the AI companion can access when generating responses.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              'Date range',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [7, 14, 30].map((days) {
                final selected = dateRangeDays == days;
                return ChoiceChip(
                  label: Text('$days days'),
                  selected: selected,
                  onSelected: busy
                      ? null
                      : (_) => onDateRangeChanged(days),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            const Text(
              'Only records within the selected time range will be included in AI context. Default: 14 days.',
              style: TextStyle(color: Colors.grey),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _BackupKeyCard extends StatelessWidget {
  const _BackupKeyCard({required this.onManageKeys});

  final VoidCallback onManageKeys;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Backup key portability'),
        subtitle: const Text(
          'Export/import encrypted backup keys (passphrase, QR, or platform key backup).',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onManageKeys,
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({
    required this.isWeb,
    required this.onBackup,
    required this.onRestore,
    required this.onAuthDiagnostics,
    required this.onViewAiCalls,
  });

  final bool isWeb;
  final VoidCallback? onBackup;
  final VoidCallback? onRestore;
  final Future<void> Function() onAuthDiagnostics;
  final VoidCallback onViewAiCalls;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostics & tools',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAuthDiagnostics,
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Run auth diagnostics'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onViewAiCalls,
              icon: const Icon(Icons.psychology_alt_outlined),
              label: const Text('View AI calls'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DesignShowcaseScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.palette_outlined),
              label: const Text('View Design Showcase'),
            ),
            const SizedBox(height: 12),
            if (!isWeb) ...[
              OutlinedButton.icon(
                onPressed: onBackup,
                icon: const Icon(Icons.backup),
                label: const Text('Backup to Google Drive'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.restore),
                label: const Text('Restore from Google Drive'),
              ),
            ] else
              const Text(
                'Drive backup/restore is available on mobile builds.\n'
                'The web build cannot access app files due to the browser sandbox.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

class AutoSyncCadenceOption {
  const AutoSyncCadenceOption._(
    this.id,
    this.label,
    this.description,
    this.interval,
    this.cadence,
  );

  final String id;
  final String label;
  final String description;
  final Duration? interval;
  final AutoSyncCadence cadence;

  static const AutoSyncCadenceOption sixHours = AutoSyncCadenceOption._(
    '6h',
    '6 hours',
    'Good for frequent updates on Wi-Fi.',
    Duration(hours: 6),
    AutoSyncCadence.sixHours,
  );

  static const AutoSyncCadenceOption twelveHours = AutoSyncCadenceOption._(
    '12h',
    '12 hours',
    'Twice per day when changes are detected.',
    Duration(hours: 12),
    AutoSyncCadence.twelveHours,
  );

  static const AutoSyncCadenceOption daily = AutoSyncCadenceOption._(
    'daily',
    'Daily',
    'Nightly backups while on Wi-Fi.',
    Duration(days: 1),
    AutoSyncCadence.daily,
  );

  static const AutoSyncCadenceOption weekly = AutoSyncCadenceOption._(
    'weekly',
    'Weekly',
    'Default cadence for worry-free coverage.',
    Duration(days: 7),
    AutoSyncCadence.weekly,
  );

  static const AutoSyncCadenceOption manual = AutoSyncCadenceOption._(
    'manual',
    'Manual',
    'Only run backups when you tap "Backup now".',
    null,
    AutoSyncCadence.manual,
  );

  static AutoSyncCadenceOption fromCadence(AutoSyncCadence cadence) {
    switch (cadence) {
      case AutoSyncCadence.sixHours:
        return sixHours;
      case AutoSyncCadence.twelveHours:
        return twelveHours;
      case AutoSyncCadence.daily:
        return daily;
      case AutoSyncCadence.weekly:
        return weekly;
      case AutoSyncCadence.manual:
        return manual;
    }
  }
}

const List<AutoSyncCadenceOption> _cadenceOptions = <AutoSyncCadenceOption>[
  AutoSyncCadenceOption.sixHours,
  AutoSyncCadenceOption.twelveHours,
  AutoSyncCadenceOption.daily,
  AutoSyncCadenceOption.weekly,
  AutoSyncCadenceOption.manual,
];

enum ThemeModePreference { light, dark, system }

extension on ThemeModePreference {
  String get label {
    switch (this) {
      case ThemeModePreference.light:
        return 'Light';
      case ThemeModePreference.dark:
        return 'Dark';
      case ThemeModePreference.system:
        return 'Auto';
    }
  }
}

enum TextScalePreference { small, medium, large }

extension on TextScalePreference {
  String get label {
    switch (this) {
      case TextScalePreference.small:
        return 'Small';
      case TextScalePreference.medium:
        return 'Medium';
      case TextScalePreference.large:
        return 'Large';
    }
  }
}

extension _AiModeLabel on AiMode {
  String get label {
    switch (this) {
      case AiMode.fake:
        return 'Fake (offline demo)';
      case AiMode.remote:
        return 'Remote (backend)';
    }
  }
}
