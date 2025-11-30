import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../utils/platform_utils.dart' as platform;

/// Key used to identify interactive_pdf annotations in PDF
const String kApdfHotspotKey = 'APDF_Hotspot';

/// Key for the embedded manifest file
const String kApdfManifestKey = 'apdf_manifest.json';

/// Marker for manifest start in PDF stream
const String kManifestStartMarker = '%%APDF_MANIFEST_START%%';

/// Marker for manifest end in PDF stream
const String kManifestEndMarker = '%%APDF_MANIFEST_END%%';

/// Advanced PDF Document with interactive hotspot support.
///
/// Wraps the `pdf` package's Document and provides methods for adding
/// pages and hotspot annotations that are stored persistently in the PDF.
///
/// Example:
/// ```dart
/// final doc = AdvancePdfDocument();
///
/// doc.addPage(
///   pageFormat: PdfPageFormat.a4,
///   build: (context) => pw.Center(
///     child: pw.Text('Hello World'),
///   ),
/// );
///
/// doc.addHotspot(
///   pageIndex: 0,
///   rect: PdfHotspotRect(left: 100, bottom: 700, width: 200, height: 50),
///   type: PdfAnnotationType.text,
///   content: PdfAnnotationContent.text('This is hidden text!'),
/// );
///
/// final bytes = await doc.save();
/// ```
class AdvancePdfDocument {
  /// The underlying pdf.Document
  final pw.Document _document;

  /// UUID generator for annotation IDs
  final Uuid _uuid = const Uuid();

  /// All hotspot annotations in this document
  final List<PdfHotspotAnnotation> _hotspots = [];

  /// Shared assets for the manifest
  final Map<String, Uint8List> _sharedAssets = {};

  /// Page sizes for coordinate calculations
  final List<PdfPageFormat> _pageSizes = [];

  /// Document title
  final String? title;

  /// Document author
  final String? author;

  /// Document subject
  final String? subject;

  /// Document keywords
  final List<String>? keywords;

  /// Document creator
  final String? creator;

  /// Creates an advanced PDF document.
  AdvancePdfDocument({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
    pw.ThemeData? theme,
  }) : _document = pw.Document(
         title: title,
         author: author,
         subject: subject,
         keywords: keywords?.join(', '),
         creator: creator ?? 'interactive_pdf',
         theme: theme,
       );

  /// Access to the underlying pdf.Document for advanced usage.
  pw.Document get raw => _document;

  /// Number of pages in the document
  int get pageCount => _pageSizes.length;

  /// All hotspot annotations in the document
  List<PdfHotspotAnnotation> get hotspots => List.unmodifiable(_hotspots);

  /// Get hotspots for a specific page
  List<PdfHotspotAnnotation> hotspotsForPage(int pageIndex) {
    return _hotspots.where((h) => h.pageIndex == pageIndex).toList();
  }

  /// Get page size for a specific page
  PdfPageFormat? getPageFormat(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pageSizes.length) return null;
    return _pageSizes[pageIndex];
  }

  /// Add a page to the document.
  ///
  /// Returns the page index of the newly added page.
  int addPage({
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.PageTheme? pageTheme,
    required pw.WidgetBuilder build,
    pw.PageOrientation? orientation,
    pw.EdgeInsets? margin,
  }) {
    final effectiveFormat = orientation == pw.PageOrientation.landscape
        ? pageFormat.landscape
        : pageFormat;

    _document.addPage(
      pw.Page(
        pageFormat: effectiveFormat,
        theme: pageTheme?.theme,
        orientation: orientation ?? pw.PageOrientation.portrait,
        margin: margin,
        build: build,
      ),
    );

    _pageSizes.add(effectiveFormat);
    return _pageSizes.length - 1;
  }

  /// Add a multi-page section to the document.
  ///
  /// Returns the starting page index.
  int addMultiPage({
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.PageTheme? pageTheme,
    required pw.WidgetBuilder build,
    pw.PageOrientation orientation = pw.PageOrientation.portrait,
    pw.EdgeInsets? margin,
    int maxPages = 100,
  }) {
    final startIndex = _pageSizes.length;
    final effectiveFormat = orientation == pw.PageOrientation.landscape
        ? pageFormat.landscape
        : pageFormat;

    _document.addPage(
      pw.MultiPage(
        pageFormat: effectiveFormat,
        theme: pageTheme?.theme,
        orientation: orientation,
        margin: margin,
        maxPages: maxPages,
        build: (context) => [build(context)],
      ),
    );

    // Note: MultiPage generates pages dynamically, we estimate 1 page here
    // The actual count is determined at save time
    _pageSizes.add(effectiveFormat);
    return startIndex;
  }

  /// Add a hotspot annotation to the document.
  ///
  /// [pageIndex] must be a valid page index (0-based).
  /// [rect] defines the hotspot region in PDF coordinates.
  /// [type] specifies the annotation type (text, image, etc.).
  /// [content] contains the data to display on long-press.
  ///
  /// Returns the created [PdfHotspotAnnotation].
  PdfHotspotAnnotation addHotspot({
    required int pageIndex,
    required PdfHotspotRect rect,
    required PdfAnnotationType type,
    required PdfAnnotationContent content,
    bool showDefaultIconInGenericViewers = false,
    bool initiallyVisibleInGenericViewers = false,
    String? label,
    String? id,
  }) {
    final annotation = PdfHotspotAnnotation(
      id: id ?? _uuid.v4(),
      pageIndex: pageIndex,
      rect: rect,
      type: type,
      content: content,
      showDefaultIconInGenericViewers: showDefaultIconInGenericViewers,
      initiallyVisibleInGenericViewers: initiallyVisibleInGenericViewers,
      label: label,
    );

    _hotspots.add(annotation);
    return annotation;
  }

  /// Add a text hotspot (convenience method).
  PdfHotspotAnnotation addTextHotspot({
    required int pageIndex,
    required PdfHotspotRect rect,
    required String text,
    String? title,
    bool showDefaultIconInGenericViewers = false,
  }) {
    return addHotspot(
      pageIndex: pageIndex,
      rect: rect,
      type: PdfAnnotationType.text,
      content: PdfAnnotationContent.text(text, title: title),
      showDefaultIconInGenericViewers: showDefaultIconInGenericViewers,
    );
  }

  /// Add an image hotspot (convenience method).
  PdfHotspotAnnotation addImageHotspot({
    required int pageIndex,
    required PdfHotspotRect rect,
    required Uint8List imageBytes,
    String? title,
    bool showDefaultIconInGenericViewers = false,
  }) {
    return addHotspot(
      pageIndex: pageIndex,
      rect: rect,
      type: PdfAnnotationType.image,
      content: PdfAnnotationContent.image(imageBytes, title: title),
      showDefaultIconInGenericViewers: showDefaultIconInGenericViewers,
    );
  }

  /// Add a shared asset that can be referenced by multiple hotspots.
  ///
  /// Returns the asset key to use in [PdfAnnotationContent.assetRef].
  String addSharedAsset(Uint8List data, {String? key}) {
    final assetKey = key ?? 'asset_${_uuid.v4()}';
    _sharedAssets[assetKey] = data;
    return assetKey;
  }

  /// Remove a hotspot by ID
  bool removeHotspot(String id) {
    final index = _hotspots.indexWhere((h) => h.id == id);
    if (index != -1) {
      _hotspots.removeAt(index);
      return true;
    }
    return false;
  }

  /// Update a hotspot
  bool updateHotspot(PdfHotspotAnnotation annotation) {
    final index = _hotspots.indexWhere((h) => h.id == annotation.id);
    if (index != -1) {
      _hotspots[index] = annotation;
      return true;
    }
    return false;
  }

  /// Clear all hotspots
  void clearHotspots() {
    _hotspots.clear();
  }

  /// Build the annotation manifest
  PdfAnnotationManifest _buildManifest() {
    return PdfAnnotationManifest(
      id: 'apdf_manifest_${DateTime.now().millisecondsSinceEpoch}',
      annotations: _hotspots,
      sharedAssets: _sharedAssets,
      metadata: {
        'title': title,
        'author': author,
        'createdAt': DateTime.now().toIso8601String(),
        'pageCount': pageCount,
      },
    );
  }

  /// Save the document to bytes.
  ///
  /// Embeds all hotspot annotations and the manifest into the PDF.
  /// The manifest is stored as a special page with encoded data that
  /// standard PDF viewers won't render but can be parsed by this package.
  Future<Uint8List> save() async {
    // Build the manifest
    final manifest = _buildManifest();
    final manifestJson = manifest.toJsonString();

    // Encode manifest to base64 for safe embedding
    final manifestBase64 = base64Encode(utf8.encode(manifestJson));

    // Add a hidden page at the end with the manifest data
    // This page contains invisible text with our encoded manifest
    if (_hotspots.isNotEmpty) {
      _document.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(1, 1), // Tiny page
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Container(
            width: 1,
            height: 1,
            child: pw.Text(
              '$kManifestStartMarker$manifestBase64$kManifestEndMarker',
              style: const pw.TextStyle(fontSize: 0.001),
            ),
          ),
        ),
      );
    }

    return _document.save();
  }

  /// Save the document to a file (native platforms only).
  ///
  /// Returns the path where the file was saved, or null on web.
  /// On web, use [save] to get the bytes and handle download via browser APIs.
  Future<String?> saveToFile(String path) async {
    final bytes = await save();
    return platform.saveToFile(path, bytes);
  }
}
