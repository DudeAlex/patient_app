import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_drive_backup/google_drive_backup.dart';
import 'package:intl/intl.dart';

import '../../features/records/data/records_service.dart';
import '../../features/sync/auto_sync_status.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _manager = DriveBackupManager();
  String? _email;
  bool _busy = false;
  RecordsService? _recordsService;
  StreamSubscription<AutoSyncStatus>? _autoSyncSubscription;
  AutoSyncStatus? _autoSyncStatus;
  bool _autoSyncBusy = false;
  bool _autoSyncInitialised = false;

  @override
  void initState() {
    super.initState();
    _restoreAccount();
    if (!kIsWeb) {
      _initAutoSync();
    }
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
    // Warm up auth headers silently to reduce latency when the user
    // triggers backup/restore shortly after opening Settings.
    final effectiveEmail = email ?? cached;
    if (effectiveEmail != null) {
      Future.microtask(
        () => _manager.auth.getAuthHeaders(promptIfNecessary: false),
      );
    }
  }

  Future<void> _initAutoSync() async {
    try {
      final service = await RecordsService.instance();
      if (!mounted) return;
      _recordsService = service;
      final initialStatus =
          service.autoSync.latestStatus ?? await service.syncState.readStatus();
      setState(() {
        _autoSyncStatus = initialStatus;
        _autoSyncInitialised = true;
      });
      _autoSyncSubscription =
          service.autoSync.statusStream.listen((AutoSyncStatus status) {
        if (!mounted) return;
        setState(() => _autoSyncStatus = status);
      });
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
      await service.syncState.setAutoSyncEnabled(value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update auto backup: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _autoSyncBusy = false);
    }
  }

  String _formatLastSynced(DateTime? timestamp) {
    if (timestamp == null) return 'Last sync: never';
    final formatter = DateFormat.yMMMd().add_jm();
    return 'Last sync: ${formatter.format(timestamp)}';
  }

  String _pendingSummary(AutoSyncStatus status) {
    return 'Pending changes — critical: ${status.pendingCriticalChanges}, routine: ${status.pendingRoutineChanges}';
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
            const SnackBar(content: Text('Sign-in cancelled or failed. Check logs.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signed in as $email')),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading backup to Drive...')));
      }
      await _manager.backupToDrive();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup uploaded to Drive')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromDrive() async {
    if (_email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      try {
        await _manager.restoreFromDrive();
      } on StateError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restoring backup...')));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore completed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
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
            )
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final status = _autoSyncStatus;
    final autoSyncEnabled = status?.autoSyncEnabled ?? false;
    final autoSyncSubtitle = !_autoSyncInitialised
        ? 'Checking auto backup status…'
        : [
            'Automatically backs up after important changes when enabled.',
            _formatLastSynced(status?.lastSyncedAt),
            if (status != null) _pendingSummary(status),
          ].join('\n');
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_email != null ? 'Signed in: $_email' : 'Not signed in'),
                ),
                ElevatedButton(
                  onPressed: _email == null ? _signIn : _signOut,
                  child: Text(_email == null ? 'Sign in' : 'Sign out'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (!isWeb) ...[
            Card(
              child: SwitchListTile.adaptive(
                title: const Text('Auto backup (beta)'),
                subtitle: Text(autoSyncSubtitle),
                value: autoSyncEnabled,
                onChanged: (!_autoSyncBusy && _autoSyncInitialised && status != null)
                    ? _toggleAutoSync
                    : null,
                secondary: _autoSyncBusy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _runAuthDiagnostics,
              icon: const Icon(Icons.bug_report),
              label: const Text('Run Auth Diagnostics'),
            ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _backupToDrive,
                icon: const Icon(Icons.backup),
                label: const Text('Backup to Google Drive'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _restoreFromDrive,
                icon: const Icon(Icons.restore),
                label: const Text('Restore from Google Drive'),
              ),
            ] else ...[
              const Text(
                'Drive backup/restore is available on mobile builds.\nThe web build cannot access app files due to browser sandbox.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
            if (_busy) const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
