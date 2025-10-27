import 'package:flutter/material.dart';
import 'package:google_drive_backup/google_drive_backup.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final manager = DriveBackupManager();
  String status = 'Idle';
  String? email;
  bool busy = false;

  Future<void> _signIn() async {
    setState(() => busy = true);
    final acc = await manager.auth.signIn();
    final current = acc?.email ?? await manager.restoreAccount();
    setState(() {
      email = current;
      status = current == null ? 'Sign-in failed' : 'Signed in as $current';
      busy = false;
    });
  }

  Future<void> _backup() async {
    setState(() {
      busy = true;
      status = 'Backing up…';
    });
    try {
      await manager.backupToDrive();
      setState(() => status = 'Backup complete');
    } catch (e) {
      setState(() => status = 'Backup failed: $e');
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      busy = true;
      status = 'Restoring…';
    });
    try {
      await manager.restoreFromDrive();
      setState(() => status = 'Restore complete');
    } catch (e) {
      setState(() => status = 'Restore failed: $e');
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Drive Backup Example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email == null ? 'Not signed in' : 'Signed in: $email'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: busy ? null : _signIn,
                    child: const Text('Sign in'),
                  ),
                  ElevatedButton(
                    onPressed: busy ? null : _backup,
                    child: const Text('Backup'),
                  ),
                  ElevatedButton(
                    onPressed: busy ? null : _restore,
                    child: const Text('Restore'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(status),
              if (busy) const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
