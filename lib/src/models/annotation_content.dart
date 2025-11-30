import 'dart:convert';
import 'dart:typed_data';

/// Content payload for a hotspot annotation.
///
/// Can contain text, image data, or custom payloads.
/// For efficiency, large images should use [assetKey] to reference
/// shared assets in the manifest rather than inline [imageBytes].
class PdfAnnotationContent {
  /// Plain text content to display
  final String? text;

  /// Image bytes (PNG/JPEG) to display
  final Uint8List? imageBytes;

  /// Reference key to a shared asset in the manifest
  final String? assetKey;

  /// Custom payload for extensibility (must be JSON-serializable)
  final Map<String, dynamic>? customPayload;

  /// Optional title/header for the annotation popup
  final String? title;

  /// Optional description or subtitle
  final String? description;

  /// Creates annotation content with the given data.
  const PdfAnnotationContent({
    this.text,
    this.imageBytes,
    this.assetKey,
    this.customPayload,
    this.title,
    this.description,
  });

  /// Creates a text-only annotation content
  factory PdfAnnotationContent.text(String text, {String? title}) {
    return PdfAnnotationContent(text: text, title: title);
  }

  /// Creates an image annotation content
  factory PdfAnnotationContent.image(Uint8List imageBytes, {String? title}) {
    return PdfAnnotationContent(imageBytes: imageBytes, title: title);
  }

  /// Creates an annotation content referencing a shared asset
  factory PdfAnnotationContent.assetRef(String assetKey, {String? title}) {
    return PdfAnnotationContent(assetKey: assetKey, title: title);
  }

  /// Whether this content has any displayable data
  bool get hasContent =>
      text != null ||
      imageBytes != null ||
      assetKey != null ||
      customPayload != null;

  /// Whether this content contains image data
  bool get hasImage => imageBytes != null || assetKey != null;

  /// Whether this content contains text
  bool get hasText => text != null && text!.isNotEmpty;

  /// Serialize to JSON map
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (text != null) json['text'] = text;
    if (imageBytes != null) {
      json['imageBytes'] = base64Encode(imageBytes!);
    }
    if (assetKey != null) json['assetKey'] = assetKey;
    if (customPayload != null) json['customPayload'] = customPayload;
    if (title != null) json['title'] = title;
    if (description != null) json['description'] = description;
    return json;
  }

  /// Deserialize from JSON map
  factory PdfAnnotationContent.fromJson(Map<String, dynamic> json) {
    return PdfAnnotationContent(
      text: json['text'] as String?,
      imageBytes: json['imageBytes'] != null
          ? base64Decode(json['imageBytes'] as String)
          : null,
      assetKey: json['assetKey'] as String?,
      customPayload: json['customPayload'] as Map<String, dynamic>?,
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Create a copy with modified fields
  PdfAnnotationContent copyWith({
    String? text,
    Uint8List? imageBytes,
    String? assetKey,
    Map<String, dynamic>? customPayload,
    String? title,
    String? description,
  }) {
    return PdfAnnotationContent(
      text: text ?? this.text,
      imageBytes: imageBytes ?? this.imageBytes,
      assetKey: assetKey ?? this.assetKey,
      customPayload: customPayload ?? this.customPayload,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfAnnotationContent &&
        other.text == text &&
        other.assetKey == assetKey &&
        other.title == title &&
        other.description == description;
    // Note: imageBytes comparison is omitted for performance
  }

  @override
  int get hashCode => Object.hash(text, assetKey, title, description);

  @override
  String toString() =>
      'PdfAnnotationContent(text: ${text?.substring(0, text!.length > 20 ? 20 : text!.length)}..., '
      'hasImage: $hasImage, assetKey: $assetKey)';
}
