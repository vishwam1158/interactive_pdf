import 'dart:convert';
import 'dart:typed_data';

import 'hotspot_annotation.dart';

/// Manifest for storing all annotations and shared assets in a PDF.
///
/// This is serialized and embedded as a file attachment in the PDF,
/// allowing efficient storage of shared assets and complete annotation data.
class PdfAnnotationManifest {
  /// Manifest format version for compatibility checking
  static const int currentVersion = 1;

  /// Version of this manifest
  final int version;

  /// Unique identifier for this manifest
  final String id;

  /// All hotspot annotations in the document
  final List<PdfHotspotAnnotation> annotations;

  /// Shared assets (images, etc.) referenced by annotations
  ///
  /// Key is the asset key, value is base64-encoded data
  final Map<String, Uint8List> sharedAssets;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Creates an annotation manifest
  const PdfAnnotationManifest({
    this.version = currentVersion,
    required this.id,
    required this.annotations,
    this.sharedAssets = const {},
    this.metadata,
  });

  /// Creates an empty manifest with a generated ID
  factory PdfAnnotationManifest.empty() {
    return PdfAnnotationManifest(
      id: 'apdf_manifest_${DateTime.now().millisecondsSinceEpoch}',
      annotations: [],
      sharedAssets: {},
    );
  }

  /// Get annotations for a specific page
  List<PdfHotspotAnnotation> annotationsForPage(int pageIndex) {
    return annotations.where((a) => a.pageIndex == pageIndex).toList();
  }

  /// Get a shared asset by key
  Uint8List? getAsset(String key) => sharedAssets[key];

  /// Check if an asset exists
  bool hasAsset(String key) => sharedAssets.containsKey(key);

  /// Serialize to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Serialize to JSON map
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'id': id,
      'annotations': annotations.map((a) => a.toJson()).toList(),
      'sharedAssets': sharedAssets.map(
        (key, value) => MapEntry(key, base64Encode(value)),
      ),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Deserialize from JSON string
  factory PdfAnnotationManifest.fromJsonString(String json) {
    return PdfAnnotationManifest.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  /// Deserialize from JSON map
  factory PdfAnnotationManifest.fromJson(Map<String, dynamic> json) {
    final annotationsJson = json['annotations'] as List<dynamic>;
    final assetsJson =
        json['sharedAssets'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return PdfAnnotationManifest(
      version: json['version'] as int? ?? currentVersion,
      id: json['id'] as String,
      annotations: annotationsJson
          .map((a) => PdfHotspotAnnotation.fromJson(a as Map<String, dynamic>))
          .toList(),
      sharedAssets: assetsJson.map(
        (key, value) => MapEntry(key, base64Decode(value as String)),
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy with modified fields
  PdfAnnotationManifest copyWith({
    int? version,
    String? id,
    List<PdfHotspotAnnotation>? annotations,
    Map<String, Uint8List>? sharedAssets,
    Map<String, dynamic>? metadata,
  }) {
    return PdfAnnotationManifest(
      version: version ?? this.version,
      id: id ?? this.id,
      annotations: annotations ?? this.annotations,
      sharedAssets: sharedAssets ?? this.sharedAssets,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Add an annotation to the manifest
  PdfAnnotationManifest addAnnotation(PdfHotspotAnnotation annotation) {
    return copyWith(annotations: [...annotations, annotation]);
  }

  /// Add a shared asset
  PdfAnnotationManifest addAsset(String key, Uint8List data) {
    return copyWith(sharedAssets: {...sharedAssets, key: data});
  }

  @override
  String toString() =>
      'PdfAnnotationManifest(id: $id, annotations: ${annotations.length}, assets: ${sharedAssets.length})';
}
