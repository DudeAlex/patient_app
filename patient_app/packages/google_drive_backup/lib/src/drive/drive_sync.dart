import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Uploads and downloads encrypted archives in the user's Drive App Data space.
class DriveSyncService {
  final http.Client client;
  DriveSyncService(this.client);

  static const fileName = 'patient-backup-v1.enc';

  Future<drive.File?> _findOrNull(drive.DriveApi api) async {
    final res = await api.files.list(
      spaces: 'appDataFolder',
      q: "name='$fileName'",
      $fields: 'files(id, name, modifiedTime)',
      pageSize: 1,
    );
    return (res.files ?? []).isNotEmpty ? res.files!.first : null;
  }

  Future<drive.File> uploadEncrypted(Uint8List bytes) async {
    final api = drive.DriveApi(client);
    final existing = await _findOrNull(api);
    final media = drive.Media(Stream<List<int>>.fromIterable([bytes]), bytes.length);
    final file = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder'];
    if (existing?.id != null) {
      return await api.files.update(file, existing!.id!, uploadMedia: media);
    } else {
      return await api.files.create(file, uploadMedia: media);
    }
  }

  Future<Uint8List?> downloadEncrypted() async {
    final api = drive.DriveApi(client);
    final existing = await _findOrNull(api);
    if (existing?.id == null) return null;
    final media = await api.files.get(
      existing!.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final chunks = <int>[];
    await for (final chunk in media.stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }
}
