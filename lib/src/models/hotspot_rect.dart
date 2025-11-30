import 'dart:ui';

/// Represents a rectangular region for a hotspot annotation in PDF coordinates.
///
/// Coordinates are in PDF user space units (points, 1/72 inch).
/// Origin is bottom-left of the page in PDF coordinate system.
class PdfHotspotRect {
  /// Left edge X coordinate in PDF points
  final double left;

  /// Bottom edge Y coordinate in PDF points (PDF origin is bottom-left)
  final double bottom;

  /// Width of the hotspot region in PDF points
  final double width;

  /// Height of the hotspot region in PDF points
  final double height;

  /// Creates a hotspot rectangle with the given position and size.
  const PdfHotspotRect({
    required this.left,
    required this.bottom,
    required this.width,
    required this.height,
  });

  /// Creates a hotspot rectangle from left, top, right, bottom coordinates.
  ///
  /// Note: [top] here refers to the visual top (higher Y value in PDF coords).
  factory PdfHotspotRect.fromLTRB(
    double left,
    double bottom,
    double right,
    double top,
  ) {
    return PdfHotspotRect(
      left: left,
      bottom: bottom,
      width: right - left,
      height: top - bottom,
    );
  }

  /// Creates a hotspot rectangle from a Flutter [Rect] and page height.
  ///
  /// Converts Flutter's top-left origin to PDF's bottom-left origin.
  factory PdfHotspotRect.fromFlutterRect(Rect rect, double pageHeight) {
    return PdfHotspotRect(
      left: rect.left,
      bottom: pageHeight - rect.bottom,
      width: rect.width,
      height: rect.height,
    );
  }

  /// Right edge X coordinate
  double get right => left + width;

  /// Top edge Y coordinate (in PDF coordinates, higher value)
  double get top => bottom + height;

  /// Center X coordinate
  double get centerX => left + width / 2;

  /// Center Y coordinate
  double get centerY => bottom + height / 2;

  /// Convert to PDF annotation rect array [llx, lly, urx, ury]
  List<double> toPdfRect() => [left, bottom, right, top];

  /// Create from PDF annotation rect array [llx, lly, urx, ury]
  factory PdfHotspotRect.fromPdfRect(List<double> rect) {
    return PdfHotspotRect.fromLTRB(rect[0], rect[1], rect[2], rect[3]);
  }

  /// Convert to Flutter [Rect] given the page height for coordinate flip.
  Rect toFlutterRect(double pageHeight) {
    return Rect.fromLTWH(left, pageHeight - top, width, height);
  }

  /// Check if a point (in PDF coordinates) is inside this rect
  bool containsPoint(double x, double y) {
    return x >= left && x <= right && y >= bottom && y <= top;
  }

  /// Check if a Flutter point (with top-left origin) is inside this rect
  bool containsFlutterPoint(Offset point, double pageHeight) {
    final pdfY = pageHeight - point.dy;
    return containsPoint(point.dx, pdfY);
  }

  /// Serialize to JSON map
  Map<String, dynamic> toJson() => {
    'left': left,
    'bottom': bottom,
    'width': width,
    'height': height,
  };

  /// Deserialize from JSON map
  factory PdfHotspotRect.fromJson(Map<String, dynamic> json) {
    return PdfHotspotRect(
      left: (json['left'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfHotspotRect &&
        other.left == left &&
        other.bottom == bottom &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(left, bottom, width, height);

  @override
  String toString() =>
      'PdfHotspotRect(left: $left, bottom: $bottom, width: $width, height: $height)';
}
