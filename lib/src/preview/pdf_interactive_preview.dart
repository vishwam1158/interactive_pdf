import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../utils/hotspot_style.dart';
import '../utils/pdf_coordinate_mapper.dart';
import 'pdf_interactive_controller.dart';

/// Builder function for custom hotspot overlay content.
typedef PdfHotspotOverlayBuilder =
    Widget Function(BuildContext context, PdfHotspotAnnotation annotation);

/// Callback when a hotspot is activated (long-pressed).
typedef PdfHotspotCallback = void Function(PdfHotspotAnnotation annotation);

/// Interactive PDF preview widget with hotspot support.
///
/// Displays PDF pages and allows users to long-press on hotspot regions
/// to reveal embedded text or images.
///
/// Example:
/// ```dart
/// PdfInteractivePreview(
///   pdfBytes: myPdfBytes,
///   onHotspotActivated: (annotation) {
///     print('Hotspot activated: ${annotation.id}');
///   },
/// )
/// ```
class PdfInteractivePreview extends StatefulWidget {
  /// PDF document bytes to display.
  final Uint8List pdfBytes;

  /// Pre-parsed hotspots (if null, will be parsed from PDF).
  final List<PdfHotspotAnnotation>? hotspots;

  /// Called when a hotspot is long-pressed.
  final PdfHotspotCallback? onHotspotActivated;

  /// Called when a hotspot overlay is dismissed.
  final PdfHotspotCallback? onHotspotDismissed;

  /// Custom builder for hotspot overlay content.
  final PdfHotspotOverlayBuilder? overlayBuilder;

  /// Initial page to display.
  final int initialPage;

  /// Called when the page changes.
  final ValueChanged<int>? onPageChanged;

  /// External controller for programmatic control.
  final PdfInteractiveController? controller;

  /// Padding around pages.
  final EdgeInsets pagePadding;

  /// Background color behind pages.
  final Color backgroundColor;

  /// Maximum zoom scale.
  final double maxScale;

  /// Minimum zoom scale.
  final double minScale;

  /// Visual style for hotspots and overlays.
  final PdfHotspotStyle style;

  /// Whether to show page numbers.
  final bool showPageNumbers;

  /// Whether to enable pinch-to-zoom.
  final bool enableZoom;

  /// Whether to enable page navigation gestures.
  final bool enablePageNavigation;

  /// DPI for page rendering (higher = better quality, more memory).
  final double renderDpi;

  /// Widget to show while loading.
  final Widget? loadingWidget;

  /// Widget to show on error.
  final Widget Function(String error)? errorBuilder;

  /// Creates an interactive PDF preview.
  const PdfInteractivePreview({
    super.key,
    required this.pdfBytes,
    this.hotspots,
    this.onHotspotActivated,
    this.onHotspotDismissed,
    this.overlayBuilder,
    this.initialPage = 0,
    this.onPageChanged,
    this.controller,
    this.pagePadding = const EdgeInsets.all(8),
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.maxScale = 4.0,
    this.minScale = 1.0,
    this.style = PdfHotspotStyle.light,
    this.showPageNumbers = true,
    this.enableZoom = true,
    this.enablePageNavigation = true,
    this.renderDpi = 150,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  State<PdfInteractivePreview> createState() => _PdfInteractivePreviewState();
}

class _PdfInteractivePreviewState extends State<PdfInteractivePreview>
    with SingleTickerProviderStateMixin {
  late PdfInteractiveController _controller;
  bool _isExternalController = false;

  // Page rendering
  final Map<int, ui.Image> _renderedPages = {};
  final Map<int, Future<void>> _renderingFutures = {};
  bool _isInitializing = true;
  String? _error;

  // Gesture handling
  Timer? _longPressTimer;

  // Animation
  late AnimationController _overlayAnimationController;
  late Animation<double> _overlayAnimation;

  // Page view controller
  late PageController _pageController;

  // Transform for zoom/pan
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();

    // Set up controller
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isExternalController = true;
    } else {
      _controller = PdfInteractiveController(
        minScale: widget.minScale,
        maxScale: widget.maxScale,
      );
    }
    _controller.addListener(_onControllerChanged);

    // Set up animation
    _overlayAnimationController = AnimationController(
      vsync: this,
      duration: widget.style.animationDuration,
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayAnimationController,
      curve: widget.style.animationCurve,
    );

    // Set up page controller
    _pageController = PageController(initialPage: widget.initialPage);

    // Initialize
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize(
        pdfBytes: widget.pdfBytes,
        hotspots: widget.hotspots,
        initialPage: widget.initialPage,
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });

        // Pre-render initial pages
        _prerenderPages(_controller.currentPage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      // Sync page controller with internal state
      if (_pageController.hasClients &&
          _pageController.page?.round() != _controller.currentPage) {
        _pageController.jumpToPage(_controller.currentPage);
      }

      setState(() {});
    }
  }

  @override
  void didUpdateWidget(PdfInteractivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pdfBytes != widget.pdfBytes) {
      _initialize();
    }

    if (oldWidget.hotspots != widget.hotspots && widget.hotspots != null) {
      _controller.updateHotspots(widget.hotspots!);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (!_isExternalController) {
      _controller.dispose();
    }
    _overlayAnimationController.dispose();
    _pageController.dispose();
    _transformController.dispose();
    _longPressTimer?.cancel();
    _disposeRenderedPages();
    super.dispose();
  }

  void _disposeRenderedPages() {
    for (final image in _renderedPages.values) {
      image.dispose();
    }
    _renderedPages.clear();
  }

  Future<void> _prerenderPages(int centerPage) async {
    // Render current, previous, and next pages
    final pagesToRender = [
      centerPage,
      if (centerPage > 0) centerPage - 1,
      if (centerPage < _controller.pageCount - 1) centerPage + 1,
    ];

    for (final pageIndex in pagesToRender) {
      if (!_renderedPages.containsKey(pageIndex)) {
        _renderPage(pageIndex);
      }
    }
  }

  Future<void> _renderPage(int pageIndex) async {
    if (_renderingFutures.containsKey(pageIndex)) return;

    final completer = Completer<void>();
    _renderingFutures[pageIndex] = completer.future;

    try {
      // Use printing package to rasterize the page
      await for (final page in Printing.raster(
        widget.pdfBytes,
        pages: [pageIndex],
        dpi: widget.renderDpi,
      )) {
        final image = await page.toImage();
        if (mounted) {
          _renderedPages[pageIndex] = image;
          setState(() {});
        }
        break;
      }
    } catch (e) {
      debugPrint('Error rendering page $pageIndex: $e');
    } finally {
      completer.complete();
      _renderingFutures.remove(pageIndex);
    }
  }

  void _onPageChanged(int page) {
    _controller.jumpToPage(page);
    widget.onPageChanged?.call(page);
    _prerenderPages(page);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    // Find hotspot at this position
    final hotspot = _findHotspotAtPosition(details.localPosition);

    if (hotspot != null) {
      _controller.setActiveHotspot(hotspot);
      _overlayAnimationController.forward();
      widget.onHotspotActivated?.call(hotspot);

      // Haptic feedback
      HapticFeedback.mediumImpact();
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_controller.activeHotspot != null) {
      final activeHotspot = _controller.activeHotspot!;
      _overlayAnimationController.reverse().then((_) {
        _controller.setActiveHotspot(null);
      });
      widget.onHotspotDismissed?.call(activeHotspot);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    // Dismiss overlay on tap
    if (_controller.activeHotspot != null) {
      _overlayAnimationController.reverse().then((_) {
        _controller.setActiveHotspot(null);
      });
    }
  }

  PdfHotspotAnnotation? _findHotspotAtPosition(Offset position) {
    final pageIndex = _controller.currentPage;
    final pageDimensions = _controller.getPageDimensions(pageIndex);
    if (pageDimensions == null) return null;

    final hotspots = _controller.hotspotsForPage(pageIndex);
    if (hotspots.isEmpty) return null;

    // Get rendered page size
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final renderedPageSize = _calculateRenderedPageSize(
      Size(pageDimensions.width, pageDimensions.height),
      renderBox.size,
    );

    // Find hotspot at position
    final matchingHotspots = PdfCoordinateMapper.findHotspotsAtPoint(
      flutterPoint: position,
      hotspots: hotspots,
      pageSizeInPoints: Size(pageDimensions.width, pageDimensions.height),
      renderedPageSize: renderedPageSize,
    );

    return matchingHotspots.isNotEmpty ? matchingHotspots.first : null;
  }

  Size _calculateRenderedPageSize(Size pageSize, Size constraints) {
    return PdfCoordinateMapper.calculateFitSize(
      pageSizeInPoints: pageSize,
      constraints: Size(
        constraints.width - widget.pagePadding.horizontal,
        constraints.height - widget.pagePadding.vertical,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError(_error!);
    }

    return Container(
      color: widget.backgroundColor,
      child: Stack(
        children: [
          // PDF pages
          _buildPageView(),

          // Hotspot indicators (if enabled)
          if (widget.style.showHotspotIndicator) _buildHotspotIndicators(),

          // Active hotspot overlay
          if (_controller.activeHotspot != null) _buildHotspotOverlay(),

          // Page numbers
          if (widget.showPageNumbers) _buildPageNumbers(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child:
          widget.loadingWidget ??
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading PDF...'),
            ],
          ),
    );
  }

  Widget _buildError(String error) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(error);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading PDF',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      child: widget.enableZoom
          ? InteractiveViewer(
              transformationController: _transformController,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              child: _buildPageContent(),
            )
          : _buildPageContent(),
    );
  }

  Widget _buildPageContent() {
    if (widget.enablePageNavigation && _controller.pageCount > 1) {
      return PageView.builder(
        controller: _pageController,
        itemCount: _controller.pageCount,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) => _buildPage(index),
      );
    } else {
      return _buildPage(_controller.currentPage);
    }
  }

  Widget _buildPage(int pageIndex) {
    final image = _renderedPages[pageIndex];

    return Padding(
      padding: widget.pagePadding,
      child: Center(
        child: image != null
            ? RawImage(image: image, fit: BoxFit.contain)
            : const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildHotspotIndicators() {
    final pageIndex = _controller.currentPage;
    final pageDimensions = _controller.getPageDimensions(pageIndex);
    if (pageDimensions == null) return const SizedBox.shrink();

    final hotspots = _controller.hotspotsForPage(pageIndex);
    if (hotspots.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final renderedPageSize = _calculateRenderedPageSize(
          Size(pageDimensions.width, pageDimensions.height),
          constraints.biggest,
        );

        // Calculate offset to center the page
        final offsetX = (constraints.maxWidth - renderedPageSize.width) / 2;
        final offsetY = (constraints.maxHeight - renderedPageSize.height) / 2;

        return Stack(
          children: hotspots.map((hotspot) {
            final rect = PdfCoordinateMapper.toFlutterRect(
              pdfRect: hotspot.rect,
              pageSizeInPoints: Size(
                pageDimensions.width,
                pageDimensions.height,
              ),
              renderedPageSize: renderedPageSize,
            );

            return Positioned(
              left: rect.left + offsetX,
              top: rect.top + offsetY,
              width: rect.width,
              height: rect.height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.style.indicatorColor,
                    borderRadius: BorderRadius.circular(
                      widget.style.borderRadius,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHotspotOverlay() {
    final annotation = _controller.activeHotspot!;

    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _overlayAnimation.value,
          child: Transform.scale(
            scale: 0.9 + (_overlayAnimation.value * 0.1),
            child: child,
          ),
        );
      },
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: widget.style.popupMaxWidth,
            maxHeight: widget.style.popupMaxHeight,
          ),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.style.popupBackgroundColor,
            borderRadius: BorderRadius.circular(widget.style.borderRadius * 2),
            boxShadow: widget.style.popupShadow,
          ),
          child: widget.overlayBuilder != null
              ? widget.overlayBuilder!(context, annotation)
              : _buildDefaultOverlay(annotation),
        ),
      ),
    );
  }

  Widget _buildDefaultOverlay(PdfHotspotAnnotation annotation) {
    final content = annotation.content;

    return SingleChildScrollView(
      padding: widget.style.popupPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (content.title != null) ...[
            Text(
              content.title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.style.popupTextColor,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Image
          if (content.imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(widget.style.borderRadius),
              child: Image.memory(content.imageBytes!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
          ],

          // Text
          if (content.text != null)
            Text(
              content.text!,
              style: TextStyle(
                fontSize: 14,
                color: widget.style.popupTextColor,
              ),
            ),

          // Description
          if (content.description != null) ...[
            const SizedBox(height: 8),
            Text(
              content.description!,
              style: TextStyle(
                fontSize: 12,
                color: widget.style.popupTextColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageNumbers() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${_controller.currentPage + 1} / ${_controller.pageCount}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
