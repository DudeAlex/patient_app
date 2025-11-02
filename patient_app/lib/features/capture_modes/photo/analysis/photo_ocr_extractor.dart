import 'dart:io';

abstract class PhotoOcrExtractor {
  Future<String?> extract(File file);
}

class StubPhotoOcrExtractor implements PhotoOcrExtractor {
  const StubPhotoOcrExtractor();

  @override
  Future<String?> extract(File file) async => null;
}
