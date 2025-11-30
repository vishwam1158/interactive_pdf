import 'dart:typed_data';

import 'package:flutter/foundation.dart';

// Conditional imports for file operations
import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart'
    as file_saver;

/// Check if the current platform is web
bool get isWeb => kIsWeb;

/// Check if the current platform is mobile (iOS or Android)
bool get isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Check if the current platform is desktop
bool get isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

/// Save bytes to a file (platform-specific implementation)
/// Returns the path where file was saved, or null on web
Future<String?> saveToFile(String fileName, Uint8List bytes) async {
  return file_saver.saveFileImpl(fileName, bytes);
}

/// Get temp directory path (null on web)
Future<String?> getTempDirectoryPath() async {
  return file_saver.getTempDirectoryPath();
}
