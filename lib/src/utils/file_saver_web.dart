import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation for file saving using browser download
Future<String?> saveFileImpl(String filePath, Uint8List bytes) async {
  try {
    // Extract filename from path
    final fileName = filePath.split('/').last.split('\\').last;

    // Create a blob from the bytes
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create download link and trigger download
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();

    // Cleanup
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    // Return a pseudo path indicating success (web doesn't have file paths)
    return 'web://download/$fileName';
  } catch (e) {
    return null;
  }
}

/// Get temp directory path - not available on web
Future<String?> getTempDirectoryPath() async {
  return null;
}
