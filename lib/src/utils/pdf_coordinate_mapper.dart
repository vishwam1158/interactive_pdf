import 'dart:ui';

import 'package:flutter/painting.dart' show BoxFit;

import '../models/models.dart';

/// Utility for mapping coordinates between PDF space and Flutter layout space.
///
/// PDF uses a bottom-left origin with points (1/72 inch) as units.
/// Flutter uses a top-left origin with logical pixels.
class PdfCoordinateMapper {
  PdfCoordinateMapper._();

  /// Convert a PDF hotspot rect to Flutter logical coordinates.
  ///
  /// [pdfRect] - Rectangle in PDF coordinates (bottom-left origin)
  /// [pageSizeInPoints] - Original PDF page size in points
  /// [renderedPageSize] - Rendered page size in Flutter logical pixels
  static Rect toFlutterRect({
    required PdfHotspotRect pdfRect,
    required Size pageSizeInPoints,
    required Size renderedPageSize,
  }) {
    // Calculate scale factors
    final scaleX = renderedPageSize.width / pageSizeInPoints.width;
    final scaleY = renderedPageSize.height / pageSizeInPoints.height;

    // Convert coordinates (flip Y axis: PDF bottom-left → Flutter top-left)
    final left = pdfRect.left * scaleX;
    final top = (pageSizeInPoints.height - pdfRect.top) * scaleY;
    final width = pdfRect.width * scaleX;
    final height = pdfRect.height * scaleY;

    return Rect.fromLTWH(left, top, width, height);
  }

  /// Convert a Flutter rect to PDF coordinates.
  ///
  /// [flutterRect] - Rectangle in Flutter logical coordinates (top-left origin)
  /// [pageSizeInPoints] - PDF page size in points
  /// [renderedPageSize] - Rendered page size in Flutter logical pixels
  static PdfHotspotRect toPdfRect({
    required Rect flutterRect,
    required Size pageSizeInPoints,
    required Size renderedPageSize,
  }) {
    // Calculate scale factors
    final scaleX = pageSizeInPoints.width / renderedPageSize.width;
    final scaleY = pageSizeInPoints.height / renderedPageSize.height;

    // Convert coordinates (flip Y axis: Flutter top-left → PDF bottom-left)
    final left = flutterRect.left * scaleX;
    final width = flutterRect.width * scaleX;
    final height = flutterRect.height * scaleY;
    final bottom =
        pageSizeInPoints.height - (flutterRect.top * scaleY) - height;

    return PdfHotspotRect(
      left: left,
      bottom: bottom,
      width: width,
      height: height,
    );
  }

  /// Convert a point from Flutter coordinates to PDF coordinates.
  static Offset toFlutterOffset({
    required double pdfX,
    required double pdfY,
    required Size pageSizeInPoints,
    required Size renderedPageSize,
  }) {
    final scaleX = renderedPageSize.width / pageSizeInPoints.width;
    final scaleY = renderedPageSize.height / pageSizeInPoints.height;

    return Offset(pdfX * scaleX, (pageSizeInPoints.height - pdfY) * scaleY);
  }

  /// Convert a point from Flutter coordinates to PDF coordinates.
  static ({double x, double y}) toPdfOffset({
    required Offset flutterOffset,
    required Size pageSizeInPoints,
    required Size renderedPageSize,
  }) {
    final scaleX = pageSizeInPoints.width / renderedPageSize.width;
    final scaleY = pageSizeInPoints.height / renderedPageSize.height;

    return (
      x: flutterOffset.dx * scaleX,
      y: pageSizeInPoints.height - (flutterOffset.dy * scaleY),
    );
  }

  /// Check if a Flutter point hits a PDF hotspot rect.
  static bool hitTest({
    required Offset flutterPoint,
    required PdfHotspotRect pdfRect,
    required Size pageSizeInPoints,
    required Size renderedPageSize,
  }) {
    final flutterRect = toFlutterRect(
      pdfRect: pdfRect,
      pageSizeInPoints: pageSizeInPoints,
      renderedPageSize: renderedPageSize,
    );

    return flutterRect.contains(flutterPoint);
  }

  /// Find all hotspots that contain a given point.
  static List<PdfHotspotAnnotation> findHotspotsAtPoint({
    required Offset flutterPoint,
    required List<PdfHotspotAnnotation> hotspots,
    required Size pageSizeInPoints,
    required Size renderedPageSize,
  }) {
    return hotspots.where((hotspot) {
      return hitTest(
        flutterPoint: flutterPoint,
        pdfRect: hotspot.rect,
        pageSizeInPoints: pageSizeInPoints,
        renderedPageSize: renderedPageSize,
      );
    }).toList();
  }

  /// Calculate the rendered size for a PDF page to fit within constraints.
  static Size calculateFitSize({
    required Size pageSizeInPoints,
    required Size constraints,
    BoxFit fit = BoxFit.contain,
  }) {
    final pageAspect = pageSizeInPoints.width / pageSizeInPoints.height;
    final constraintAspect = constraints.width / constraints.height;

    switch (fit) {
      case BoxFit.contain:
        if (pageAspect > constraintAspect) {
          // Page is wider than constraints - fit to width
          return Size(constraints.width, constraints.width / pageAspect);
        } else {
          // Page is taller than constraints - fit to height
          return Size(constraints.height * pageAspect, constraints.height);
        }

      case BoxFit.cover:
        if (pageAspect > constraintAspect) {
          // Page is wider - fit to height
          return Size(constraints.height * pageAspect, constraints.height);
        } else {
          // Page is taller - fit to width
          return Size(constraints.width, constraints.width / pageAspect);
        }

      case BoxFit.fill:
        return constraints;

      case BoxFit.fitWidth:
        return Size(constraints.width, constraints.width / pageAspect);

      case BoxFit.fitHeight:
        return Size(constraints.height * pageAspect, constraints.height);

      default:
        return calculateFitSize(
          pageSizeInPoints: pageSizeInPoints,
          constraints: constraints,
          fit: BoxFit.contain,
        );
    }
  }
}
