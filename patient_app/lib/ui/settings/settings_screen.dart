import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../core/auth/auth_client.dart';
import '../../core/auth/google_auth.dart';
import '../../core/backup/backup_service.dart';
import '../../core/crypto/key_manager.dart';
import '../../core/sync/drive_sync.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = GoogleAuthService();
  GoogleSignInAccount? _account;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restoreAccount();
  }

  Future<void> _restoreAccount() async {
    final acc = await GoogleSignIn(scopes: const [
      'https://www.googleapis.com/auth/drive.appdata',
    ]).signInSilently();
    setState(() => _account = acc);
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final acc = await _auth.signIn();
      setState(() => _account = acc);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await _auth.signOut();
      setState(() => _account = null);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _backupToDrive() async {
    if (_account == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      final key = await KeyManager.getOrCreateKey();
      final encrypted = await BackupService.exportEncrypted(key);
      final client = GoogleAuthClient(GoogleSignIn(scopes: const [
        'https://www.googleapis.com/auth/drive.appdata',
      ]), http.Client());
      final drive = DriveSyncService(client);
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
    if (_account == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      final key = await KeyManager.getOrCreateKey();
      final client = GoogleAuthClient(GoogleSignIn(scopes: const [
        'https://www.googleapis.com/auth/drive.appdata',
      ]), http.Client());
      final drive = DriveSyncService(client);
      final bytes = await drive.downloadEncrypted();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No backup found in Drive')));
        }
        return;
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
                  child: Text(_account != null ? 'Signed in: ${_account!.email}' : 'Not signed in'),
                ),
                ElevatedButton(
                  onPressed: _account == null ? _signIn : _signOut,
                  child: Text(_account == null ? 'Sign in' : 'Sign out'),
                ),
              ],
            ),
            const SizedBox(height: 24),
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

