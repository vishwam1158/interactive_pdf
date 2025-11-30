import 'dart:typed_data';

/// Stub implementation - should never be called directly
/// This file exists for conditional import resolution
Future<String?> saveFileImpl(String filePath, Uint8List bytes) async {
  throw UnsupportedError('Cannot save file without dart:io or dart:html');
}

/// Stub implementation
Future<String?> getTempDirectoryPath() async {
  return null;
}
