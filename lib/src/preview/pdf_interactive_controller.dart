import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../parser/advance_pdf_parser.dart';

/// Controller for [PdfInteractivePreview].
///
/// Provides programmatic control over page navigation, hotspot display,
/// and zoom/pan interactions.
class PdfInteractiveController extends ChangeNotifier {
  /// PDF document bytes
  Uint8List? _pdfBytes;

  /// Parsed hotspot annotations
  List<PdfHotspotAnnotation> _hotspots = [];

  /// Page dimensions from PDF
  List<({double width, double height})> _pageDimensions = [];

  /// Rendered page images cache
  final Map<int, ui.Image> _pageImageCache = {};

  /// Current page index
  int _currentPage = 0;

  /// Total page count
  int _pageCount = 0;

  /// Currently active (long-pressed) hotspot
  PdfHotspotAnnotation? _activeHotspot;

  /// Current zoom scale
  double _scale = 1.0;

  /// Minimum zoom scale
  final double minScale;

  /// Maximum zoom scale
  final double maxScale;

  /// Whether the controller is initialized
  bool _isInitialized = false;

  /// Whether pages are currently being rendered
  bool _isRendering = false;

  /// Error message if initialization failed
  String? _errorMessage;

  /// Creates a PDF interactive controller.
  PdfInteractiveController({this.minScale = 1.0, this.maxScale = 4.0});

  /// Current page index (0-based)
  int get currentPage => _currentPage;

  /// Total number of pages
  int get pageCount => _pageCount;

  /// Whether the controller is initialized with PDF data
  bool get isInitialized => _isInitialized;

  /// Whether pages are currently being rendered
  bool get isRendering => _isRendering;

  /// Error message if initialization failed
  String? get errorMessage => _errorMessage;

  /// Currently active hotspot (if any)
  PdfHotspotAnnotation? get activeHotspot => _activeHotspot;

  /// Current zoom scale
  double get scale => _scale;

  /// All hotspot annotations
  List<PdfHotspotAnnotation> get hotspots => List.unmodifiable(_hotspots);

  /// Page dimensions
  List<({double width, double height})> get pageDimensions =>
      List.unmodifiable(_pageDimensions);

  /// Get hotspots for the current page
  List<PdfHotspotAnnotation> get currentPageHotspots =>
      hotspotsForPage(_currentPage);

  /// Get hotspots for a specific page
  List<PdfHotspotAnnotation> hotspotsForPage(int pageIndex) {
    return _hotspots.where((h) => h.pageIndex == pageIndex).toList();
  }

  /// Get page dimensions for a specific page
  ({double width, double height})? getPageDimensions(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pageDimensions.length) return null;
    return _pageDimensions[pageIndex];
  }

  /// Initialize with PDF bytes and optional pre-parsed hotspots.
  Future<void> initialize({
    required Uint8List pdfBytes,
    List<PdfHotspotAnnotation>? hotspots,
    int initialPage = 0,
  }) async {
    _pdfBytes = pdfBytes;
    _errorMessage = null;
    _isRendering = true;
    notifyListeners();

    try {
      // Parse hotspots from PDF if not provided
      if (hotspots != null) {
        _hotspots = List.from(hotspots);
      } else {
        _hotspots = await AdvancePdfParser.parseHotspots(pdfBytes);
      }

      // Get page dimensions
      _pageDimensions = await AdvancePdfParser.getPageDimensions(pdfBytes);
      _pageCount = _pageDimensions.length;

      // Set initial page
      _currentPage = initialPage.clamp(0, _pageCount - 1);

      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Failed to initialize PDF: $e';
      _isInitialized = false;
    } finally {
      _isRendering = false;
      notifyListeners();
    }
  }

  /// Update hotspots without reinitializing the PDF.
  void updateHotspots(List<PdfHotspotAnnotation> hotspots) {
    _hotspots = List.from(hotspots);
    notifyListeners();
  }

  /// Add a hotspot.
  void addHotspot(PdfHotspotAnnotation hotspot) {
    _hotspots.add(hotspot);
    notifyListeners();
  }

  /// Remove a hotspot by ID.
  bool removeHotspot(String id) {
    final initialLength = _hotspots.length;
    _hotspots.removeWhere((h) => h.id == id);
    final removed = _hotspots.length < initialLength;
    if (removed) notifyListeners();
    return removed;
  }

  /// Jump to a specific page.
  void jumpToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pageCount) return;
    if (_currentPage == pageIndex) return;

    _currentPage = pageIndex;
    _activeHotspot = null;
    notifyListeners();
  }

  /// Go to the next page.
  void nextPage() {
    if (_currentPage < _pageCount - 1) {
      jumpToPage(_currentPage + 1);
    }
  }

  /// Go to the previous page.
  void previousPage() {
    if (_currentPage > 0) {
      jumpToPage(_currentPage - 1);
    }
  }

  /// Go to the first page.
  void firstPage() {
    jumpToPage(0);
  }

  /// Go to the last page.
  void lastPage() {
    jumpToPage(_pageCount - 1);
  }

  /// Show a hotspot overlay programmatically.
  void showHotspot(String hotspotId) {
    final hotspot = _hotspots.firstWhere(
      (h) => h.id == hotspotId,
      orElse: () => throw ArgumentError('Hotspot not found: $hotspotId'),
    );

    // Navigate to the hotspot's page if needed
    if (hotspot.pageIndex != _currentPage) {
      _currentPage = hotspot.pageIndex;
    }

    _activeHotspot = hotspot;
    notifyListeners();
  }

  /// Hide the currently active hotspot overlay.
  void hideHotspot() {
    if (_activeHotspot != null) {
      _activeHotspot = null;
      notifyListeners();
    }
  }

  /// Set the active hotspot (called by preview widget on long press).
  void setActiveHotspot(PdfHotspotAnnotation? hotspot) {
    if (_activeHotspot != hotspot) {
      _activeHotspot = hotspot;
      notifyListeners();
    }
  }

  /// Set the zoom scale.
  void setScale(double newScale) {
    final clampedScale = newScale.clamp(minScale, maxScale);
    if (_scale != clampedScale) {
      _scale = clampedScale;
      notifyListeners();
    }
  }

  /// Reset zoom to default.
  void resetZoom() {
    setScale(1.0);
  }

  /// Get the PDF bytes.
  Uint8List? get pdfBytes => _pdfBytes;

  /// Cache a rendered page image.
  void cachePageImage(int pageIndex, ui.Image image) {
    _pageImageCache[pageIndex] = image;
  }

  /// Get a cached page image.
  ui.Image? getCachedPageImage(int pageIndex) {
    return _pageImageCache[pageIndex];
  }

  /// Clear the page image cache.
  void clearCache() {
    for (final image in _pageImageCache.values) {
      image.dispose();
    }
    _pageImageCache.clear();
  }

  /// Check if a page is cached.
  bool isPageCached(int pageIndex) {
    return _pageImageCache.containsKey(pageIndex);
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
