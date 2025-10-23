import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/auth/auth_client.dart' if (dart.library.html) '../../core/auth/auth_client_web.dart';
import '../../core/auth/google_auth.dart' if (dart.library.html) '../../core/auth/google_auth_web.dart';
import '../../core/backup/backup_service.dart' if (dart.library.html) '../../core/backup/backup_service_web.dart';
import '../../core/crypto/key_manager.dart';
import '../../core/sync/drive_sync.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = GoogleAuthService();
  String? _email;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restoreAccount();
  }

  Future<void> _restoreAccount() async {
    final email = await _auth.tryGetEmail();
    setState(() => _email = email);
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final acc = await _auth.signIn();
      final email = await _auth.tryGetEmail();
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
      await _auth.signOut();
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
      final key = await KeyManager.getOrCreateKey();
      final encrypted = await BackupService.exportEncrypted(key);
      final client = GoogleAuthClient(() async => await _auth.getAuthHeaders(promptIfNecessary: true), http.Client());
      final drive = DriveSyncService(client);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading backup to Drive...')));
      }
      await drive.uploadEncrypted(encrypted);
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
      final key = await KeyManager.getOrCreateKey();
      final client = GoogleAuthClient(() async => await _auth.getAuthHeaders(promptIfNecessary: true), http.Client());
      final drive = DriveSyncService(client);
      final bytes = await drive.downloadEncrypted();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No backup found in Drive')));
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restoring backup...')));
      }
      await BackupService.importEncrypted(bytes, key);
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

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
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
