import 'dart:convert';
import 'dart:typed_data';

import '../document/advance_pdf_document.dart';
import '../models/models.dart';

/// Parser for loading and extracting hotspot annotations from existing PDFs.
///
/// This class provides methods to parse PDFs that were created with
/// [AdvancePdfDocument] and extract the embedded hotspot data.
class AdvancePdfParser {
  AdvancePdfParser._();

  /// Parse hotspot annotations from PDF bytes.
  ///
  /// Returns a list of [PdfHotspotAnnotation] found in the PDF.
  /// If the PDF doesn't contain interactive_pdf annotations,
  /// returns an empty list.
  static Future<List<PdfHotspotAnnotation>> parseHotspots(
    Uint8List pdfBytes,
  ) async {
    final manifest = await parseManifest(pdfBytes);
    return manifest?.annotations ?? [];
  }

  /// Parse the annotation manifest from PDF bytes.
  ///
  /// Returns the [PdfAnnotationManifest] embedded in the PDF,
  /// or null if no manifest is found.
  static Future<PdfAnnotationManifest?> parseManifest(
    Uint8List pdfBytes,
  ) async {
    try {
      final pdfString = String.fromCharCodes(pdfBytes);

      // Look for manifest markers
      final startIndex = pdfString.indexOf(kManifestStartMarker);
      if (startIndex == -1) return null;

      final endIndex = pdfString.indexOf(
        kManifestEndMarker,
        startIndex + kManifestStartMarker.length,
      );
      if (endIndex == -1) return null;

      // Extract base64 encoded manifest
      final manifestBase64 = pdfString.substring(
        startIndex + kManifestStartMarker.length,
        endIndex,
      );

      // Decode from base64
      final manifestBytes = base64Decode(manifestBase64);
      final manifestJson = utf8.decode(manifestBytes);

      return PdfAnnotationManifest.fromJsonString(manifestJson);
    } catch (e) {
      // PDF doesn't contain valid manifest
      return null;
    }
  }

  /// Get page dimensions from PDF bytes.
  ///
  /// Returns a list of page sizes in points (width, height).
  static Future<List<({double width, double height})>> getPageDimensions(
    Uint8List pdfBytes,
  ) async {
    final dimensions = <({double width, double height})>[];

    try {
      final pdfString = String.fromCharCodes(pdfBytes);

      // Find all MediaBox entries
      final mediaBoxRegex = RegExp(
        r'/MediaBox\s*\[\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s*\]',
      );
      final matches = mediaBoxRegex.allMatches(pdfString);

      for (final match in matches) {
        final x1 = double.tryParse(match.group(1) ?? '0') ?? 0;
        final y1 = double.tryParse(match.group(2) ?? '0') ?? 0;
        final x2 = double.tryParse(match.group(3) ?? '612') ?? 612;
        final y2 = double.tryParse(match.group(4) ?? '792') ?? 792;

        dimensions.add((width: x2 - x1, height: y2 - y1));
      }

      // If no MediaBox found, return default A4 size
      if (dimensions.isEmpty) {
        dimensions.add((width: 595.0, height: 842.0)); // A4
      }

      // Remove any tiny pages (like our manifest page)
      dimensions.removeWhere((d) => d.width < 10 || d.height < 10);

      if (dimensions.isEmpty) {
        dimensions.add((width: 595.0, height: 842.0)); // Default A4
      }
    } catch (e) {
      dimensions.add((width: 595.0, height: 842.0)); // Default A4
    }

    return dimensions;
  }

  /// Check if a PDF contains interactive_pdf annotations.
  static Future<bool> hasHotspots(Uint8List pdfBytes) async {
    try {
      final pdfString = String.fromCharCodes(pdfBytes);
      return pdfString.contains(kManifestStartMarker);
    } catch (e) {
      return false;
    }
  }

  /// Get the page count from PDF bytes.
  static Future<int> getPageCount(Uint8List pdfBytes) async {
    final dimensions = await getPageDimensions(pdfBytes);
    return dimensions.length;
  }
}
