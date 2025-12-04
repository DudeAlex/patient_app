// Debug utility to verify attachment persistence
// Run with: dart run tool/verify_attachment_persistence.dart

import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:patient_app/features/records/adapters/storage/record_isar_model.dart';
import 'package:patient_app/features/records/model/attachment.dart';

/// Utility to inspect and verify attachment persistence in the database.
/// 
/// This script helps verify:
/// - Attachments are linked to records with correct recordId
/// - Attachment metadata includes path, MIME type, size, and timestamp
/// - Files exist at the specified paths
Future<void> main() async {
  print('=== Attachment Persistence Verification ===\n');

  try {
    // Initialize Isar
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [RecordSchema, AttachmentSchema],
      directory: dir.path,
    );

    print('Database location: ${dir.path}\n');

    // Fetch all records with attachments
    final records = await isar.records.where().findAll();
    print('Total records: ${records.length}\n');

    if (records.isEmpty) {
      print('No records found. Upload and save a file first.');
      await isar.close();
      return;
    }

    // Check each record for attachments
    for (final record in records) {
      print('--- Record ID: ${record.id} ---');
      print('Title: ${record.title}');
      print('Type: ${record.type}');
      print('Date: ${record.date}');

      // Fetch attachments for this record
      final attachments = await isar.attachments
          .filter()
          .recordIdEqualTo(record.id)
          .findAll();

      if (attachments.isEmpty) {
        print('No attachments\n');
        continue;
      }

      print('Attachments: ${attachments.length}');

      for (var i = 0; i < attachments.length; i++) {
        final attachment = attachments[i];
        print('\n  Attachment ${i + 1}:');
        print('    ID: ${attachment.id}');
        print('    RecordId: ${attachment.recordId}');
        print('    Path: ${attachment.path}');
        print('    Kind: ${attachment.kind}');
        print('    MIME Type: ${attachment.mimeType}');
        print('    Size: ${attachment.sizeBytes} bytes');
        print('    Captured At: ${attachment.capturedAt}');
        print('    Source: ${attachment.source}');
        print('    Created At: ${attachment.createdAt}');
        print('    Metadata: ${attachment.metadataJson}');

        // Verify file exists
        final attachmentFile = File('${dir.path}/attachments/${attachment.path}');
        final exists = await attachmentFile.exists();
        print('    File Exists: ${exists ? "✓ YES" : "✗ NO"}');

        if (exists) {
          final fileSize = await attachmentFile.length();
          final sizeMatch = fileSize == attachment.sizeBytes;
          print('    File Size Match: ${sizeMatch ? "✓ YES" : "✗ NO (actual: $fileSize)"}');
        }

        // Verify recordId link
        final recordIdMatch = attachment.recordId == record.id;
        print('    RecordId Link: ${recordIdMatch ? "✓ VALID" : "✗ INVALID"}');
      }

      print('');
    }

    // Summary
    final totalAttachments = await isar.attachments.count();
    print('\n=== Summary ===');
    print('Total Records: ${records.length}');
    print('Total Attachments: $totalAttachments');

    // Check for orphaned attachments
    final allAttachments = await isar.attachments.where().findAll();
    final recordIds = records.map((r) => r.id).toSet();
    final orphaned = allAttachments.where((a) => !recordIds.contains(a.recordId)).toList();

    if (orphaned.isNotEmpty) {
      print('\n⚠ Warning: ${orphaned.length} orphaned attachments found (recordId not in records table)');
      for (final attachment in orphaned) {
        print('  - Attachment ID ${attachment.id} references non-existent record ${attachment.recordId}');
      }
    } else {
      print('✓ No orphaned attachments');
    }

    await isar.close();
    print('\n=== Verification Complete ===');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
