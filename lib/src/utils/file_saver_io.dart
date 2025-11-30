import 'dart:io';
import 'dart:typed_data';

/// Native implementation for file saving
/// [filePath] can be a full path or just a filename (saves to temp dir)
Future<String?> saveFileImpl(String filePath, Uint8List bytes) async {
  try {
    // If it's a full path (contains path separator), use it directly
    // Otherwise, save to temp directory
    final String fullPath;
    if (filePath.contains('/') || filePath.contains('\\')) {
      fullPath = filePath;
    } else {
      final tempDir = Directory.systemTemp;
      fullPath = '${tempDir.path}/$filePath';
    }

    final file = File(fullPath);
    // Create parent directories if they don't exist
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (e) {
    return null;
  }
}

/// Get temp directory path
Future<String?> getTempDirectoryPath() async {
  try {
    return Directory.systemTemp.path;
  } catch (e) {
    return null;
  }
}
