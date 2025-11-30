import 'annotation_type.dart';
import 'annotation_content.dart';
import 'hotspot_rect.dart';

/// A hotspot annotation that can be embedded in a PDF.
///
/// When the PDF is viewed in [PdfInteractivePreview], long-pressing
/// on this hotspot region will reveal the embedded content.
class PdfHotspotAnnotation {
  /// Unique identifier for this annotation
  final String id;

  /// Zero-based page index where this annotation appears
  final int pageIndex;

  /// Rectangular region of the hotspot in PDF coordinates
  final PdfHotspotRect rect;

  /// Type of annotation (text, image, etc.)
  final PdfAnnotationType type;

  /// Content to display when the hotspot is activated
  final PdfAnnotationContent content;

  /// Whether to show a default icon in generic PDF viewers
  ///
  /// If true, a small annotation icon may appear in non-Flutter viewers.
  /// If false, the annotation is completely invisible in generic viewers.
  final bool showDefaultIconInGenericViewers;

  /// Whether the annotation is initially visible in generic viewers
  ///
  /// Controls the PDF annotation flags for visibility.
  final bool initiallyVisibleInGenericViewers;

  /// Optional label for developer reference (not shown to users)
  final String? label;

  /// Creates a hotspot annotation
  const PdfHotspotAnnotation({
    required this.id,
    required this.pageIndex,
    required this.rect,
    required this.type,
    required this.content,
    this.showDefaultIconInGenericViewers = false,
    this.initiallyVisibleInGenericViewers = false,
    this.label,
  });

  /// Serialize to JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'pageIndex': pageIndex,
    'rect': rect.toJson(),
    'type': type.identifier,
    'content': content.toJson(),
    'showDefaultIcon': showDefaultIconInGenericViewers,
    'initiallyVisible': initiallyVisibleInGenericViewers,
    if (label != null) 'label': label,
  };

  /// Deserialize from JSON map
  factory PdfHotspotAnnotation.fromJson(Map<String, dynamic> json) {
    return PdfHotspotAnnotation(
      id: json['id'] as String,
      pageIndex: json['pageIndex'] as int,
      rect: PdfHotspotRect.fromJson(json['rect'] as Map<String, dynamic>),
      type: PdfAnnotationTypeExtension.fromIdentifier(json['type'] as String),
      content: PdfAnnotationContent.fromJson(
        json['content'] as Map<String, dynamic>,
      ),
      showDefaultIconInGenericViewers:
          json['showDefaultIcon'] as bool? ?? false,
      initiallyVisibleInGenericViewers:
          json['initiallyVisible'] as bool? ?? false,
      label: json['label'] as String?,
    );
  }

  /// Create a copy with modified fields
  PdfHotspotAnnotation copyWith({
    String? id,
    int? pageIndex,
    PdfHotspotRect? rect,
    PdfAnnotationType? type,
    PdfAnnotationContent? content,
    bool? showDefaultIconInGenericViewers,
    bool? initiallyVisibleInGenericViewers,
    String? label,
  }) {
    return PdfHotspotAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      rect: rect ?? this.rect,
      type: type ?? this.type,
      content: content ?? this.content,
      showDefaultIconInGenericViewers:
          showDefaultIconInGenericViewers ??
          this.showDefaultIconInGenericViewers,
      initiallyVisibleInGenericViewers:
          initiallyVisibleInGenericViewers ??
          this.initiallyVisibleInGenericViewers,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfHotspotAnnotation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PdfHotspotAnnotation(id: $id, page: $pageIndex, type: $type)';
}
