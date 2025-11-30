/// Types of hotspot annotations supported by the package
enum PdfAnnotationType {
  /// Plain text annotation - displays text on long-press
  text,

  /// Image annotation - displays an image on long-press
  image,

  /// Rich text annotation with formatting support
  richText,

  /// Custom annotation type for extensibility
  custom,
}

/// Extension methods for [PdfAnnotationType]
extension PdfAnnotationTypeExtension on PdfAnnotationType {
  /// Convert to string identifier for PDF storage
  String get identifier {
    switch (this) {
      case PdfAnnotationType.text:
        return 'text';
      case PdfAnnotationType.image:
        return 'image';
      case PdfAnnotationType.richText:
        return 'richText';
      case PdfAnnotationType.custom:
        return 'custom';
    }
  }

  /// Parse from string identifier
  static PdfAnnotationType fromIdentifier(String id) {
    switch (id) {
      case 'text':
        return PdfAnnotationType.text;
      case 'image':
        return PdfAnnotationType.image;
      case 'richText':
        return PdfAnnotationType.richText;
      case 'custom':
      default:
        return PdfAnnotationType.custom;
    }
  }
}
