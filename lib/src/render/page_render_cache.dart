import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

/// Configuration for page render cache.
class PageRenderCacheConfig {
  /// Maximum number of pages to keep in memory cache.
  final int maxCachedPages;

  /// DPI for rendering pages.
  final double renderDpi;

  /// Whether to pre-render adjacent pages.
  final bool preRenderAdjacent;

  /// Number of adjacent pages to pre-render on each side.
  final int preRenderCount;

  /// Creates cache configuration.
  const PageRenderCacheConfig({
    this.maxCachedPages = 5,
    this.renderDpi = 150,
    this.preRenderAdjacent = true,
    this.preRenderCount = 1,
  });

  /// Low memory configuration
  static const PageRenderCacheConfig lowMemory = PageRenderCacheConfig(
    maxCachedPages: 3,
    renderDpi: 100,
    preRenderAdjacent: false,
    preRenderCount: 0,
  );

  /// High quality configuration
  static const PageRenderCacheConfig highQuality = PageRenderCacheConfig(
    maxCachedPages: 10,
    renderDpi: 300,
    preRenderAdjacent: true,
    preRenderCount: 2,
  );
}

/// LRU cache entry for rendered pages.
class _CacheEntry {
  final ui.Image image;
  final int pageIndex;
  final DateTime timestamp;

  _CacheEntry({
    required this.image,
    required this.pageIndex,
    required this.timestamp,
  });
}

/// Efficient cache for rendered PDF page images.
///
/// Uses LRU eviction policy to manage memory while keeping
/// frequently accessed pages readily available.
class PageRenderCache {
  /// PDF document bytes
  final Uint8List pdfBytes;

  /// Total page count
  final int pageCount;

  /// Cache configuration
  final PageRenderCacheConfig config;

  /// LRU cache storage
  final LinkedHashMap<int, _CacheEntry> _cache = LinkedHashMap();

  /// Currently rendering pages
  final Map<int, Completer<ui.Image?>> _renderingPages = {};

  /// Listeners for cache updates
  final List<VoidCallback> _listeners = [];

  /// Creates a page render cache.
  PageRenderCache({
    required this.pdfBytes,
    required this.pageCount,
    this.config = const PageRenderCacheConfig(),
  });

  /// Number of currently cached pages.
  int get cachedCount => _cache.length;

  /// Get a cached page image.
  ///
  /// Returns null if the page is not cached.
  ui.Image? getPage(int pageIndex) {
    final entry = _cache.remove(pageIndex);
    if (entry != null) {
      // Re-insert to mark as recently used (LRU)
      _cache[pageIndex] = entry;
      return entry.image;
    }
    return null;
  }

  /// Check if a page is cached.
  bool hasPage(int pageIndex) => _cache.containsKey(pageIndex);

  /// Check if a page is currently being rendered.
  bool isRendering(int pageIndex) => _renderingPages.containsKey(pageIndex);

  /// Render and cache a page.
  ///
  /// Returns the rendered image, or null if rendering failed.
  Future<ui.Image?> renderPage(int pageIndex) async {
    // Return cached if available
    if (_cache.containsKey(pageIndex)) {
      return getPage(pageIndex);
    }

    // Wait for existing render if in progress
    if (_renderingPages.containsKey(pageIndex)) {
      return _renderingPages[pageIndex]!.future;
    }

    // Start new render
    final completer = Completer<ui.Image?>();
    _renderingPages[pageIndex] = completer;

    try {
      final image = await _doRender(pageIndex);
      if (image != null) {
        _addToCache(pageIndex, image);
      }
      completer.complete(image);
      return image;
    } catch (e) {
      completer.complete(null);
      return null;
    } finally {
      _renderingPages.remove(pageIndex);
    }
  }

  /// Render a page asynchronously.
  Future<ui.Image?> _doRender(int pageIndex) async {
    try {
      await for (final page in Printing.raster(
        pdfBytes,
        pages: [pageIndex],
        dpi: config.renderDpi,
      )) {
        return page.toImage();
      }
      return null;
    } catch (e) {
      debugPrint('Error rendering page $pageIndex: $e');
      return null;
    }
  }

  /// Add a page to the cache with LRU eviction.
  void _addToCache(int pageIndex, ui.Image image) {
    // Evict oldest entries if at capacity
    while (_cache.length >= config.maxCachedPages) {
      final oldest = _cache.keys.first;
      final entry = _cache.remove(oldest);
      entry?.image.dispose();
    }

    _cache[pageIndex] = _CacheEntry(
      image: image,
      pageIndex: pageIndex,
      timestamp: DateTime.now(),
    );

    _notifyListeners();
  }

  /// Pre-render pages around the given center page.
  Future<void> preRenderAround(int centerPage) async {
    if (!config.preRenderAdjacent) return;

    final pagesToRender = <int>[];

    for (var i = 1; i <= config.preRenderCount; i++) {
      if (centerPage - i >= 0) pagesToRender.add(centerPage - i);
      if (centerPage + i < pageCount) pagesToRender.add(centerPage + i);
    }

    // Render in parallel
    await Future.wait(
      pagesToRender.map((p) => renderPage(p)),
      eagerError: false,
    );
  }

  /// Ensure a page is rendered (render if not cached).
  Future<ui.Image?> ensurePage(int pageIndex) async {
    if (hasPage(pageIndex)) {
      return getPage(pageIndex);
    }
    return renderPage(pageIndex);
  }

  /// Clear specific page from cache.
  void evictPage(int pageIndex) {
    final entry = _cache.remove(pageIndex);
    entry?.image.dispose();
    _notifyListeners();
  }

  /// Clear all cached pages.
  void clear() {
    for (final entry in _cache.values) {
      entry.image.dispose();
    }
    _cache.clear();
    _notifyListeners();
  }

  /// Add a listener for cache updates.
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a listener.
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Dispose the cache and release all resources.
  void dispose() {
    clear();
    _listeners.clear();
    for (final completer in _renderingPages.values) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _renderingPages.clear();
  }

  /// Get cache statistics.
  Map<String, dynamic> getStats() {
    return {
      'cachedPages': _cache.length,
      'maxCachedPages': config.maxCachedPages,
      'renderingPages': _renderingPages.length,
      'renderDpi': config.renderDpi,
      'preRenderEnabled': config.preRenderAdjacent,
    };
  }
}
