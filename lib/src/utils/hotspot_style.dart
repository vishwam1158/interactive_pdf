import 'package:flutter/material.dart';

/// Visual styling configuration for hotspot regions and overlays.
class PdfHotspotStyle {
  /// Background color for hotspot highlight when detected
  final Color highlightColor;

  /// Border radius for hotspot regions
  final double borderRadius;

  /// Border width for hotspot outline
  final double borderWidth;

  /// Border color for hotspot outline
  final Color borderColor;

  /// Background color for the annotation popup
  final Color popupBackgroundColor;

  /// Text color for the annotation popup
  final Color popupTextColor;

  /// Shadow for the popup overlay
  final List<BoxShadow> popupShadow;

  /// Padding inside the popup
  final EdgeInsets popupPadding;

  /// Maximum width for the popup
  final double popupMaxWidth;

  /// Maximum height for the popup
  final double popupMaxHeight;

  /// Animation duration for showing/hiding overlays
  final Duration animationDuration;

  /// Animation curve for overlays
  final Curve animationCurve;

  /// Duration user must hold before hotspot activates
  final Duration longPressDuration;

  /// Whether to show a subtle indicator on hotspot regions
  final bool showHotspotIndicator;

  /// Indicator color (if [showHotspotIndicator] is true)
  final Color indicatorColor;

  /// Creates a hotspot style configuration.
  const PdfHotspotStyle({
    this.highlightColor = const Color(0x330066FF),
    this.borderRadius = 4.0,
    this.borderWidth = 1.5,
    this.borderColor = const Color(0x660066FF),
    this.popupBackgroundColor = Colors.white,
    this.popupTextColor = Colors.black87,
    this.popupShadow = const [
      BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    this.popupPadding = const EdgeInsets.all(16),
    this.popupMaxWidth = 300,
    this.popupMaxHeight = 400,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOutCubic,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.showHotspotIndicator = false,
    this.indicatorColor = const Color(0x220066FF),
  });

  /// Default light theme style
  static const PdfHotspotStyle light = PdfHotspotStyle();

  /// Dark theme style
  static const PdfHotspotStyle dark = PdfHotspotStyle(
    highlightColor: Color(0x334499FF),
    borderColor: Color(0x664499FF),
    popupBackgroundColor: Color(0xFF2D2D2D),
    popupTextColor: Colors.white,
    indicatorColor: Color(0x224499FF),
  );

  /// Minimal style with no indicators
  static const PdfHotspotStyle minimal = PdfHotspotStyle(
    showHotspotIndicator: false,
    highlightColor: Color(0x00000000),
    borderWidth: 0,
  );

  /// Style with visible hotspot indicators
  static const PdfHotspotStyle withIndicators = PdfHotspotStyle(
    showHotspotIndicator: true,
    indicatorColor: Color(0x330066FF),
  );

  /// Create a copy with modified properties
  PdfHotspotStyle copyWith({
    Color? highlightColor,
    double? borderRadius,
    double? borderWidth,
    Color? borderColor,
    Color? popupBackgroundColor,
    Color? popupTextColor,
    List<BoxShadow>? popupShadow,
    EdgeInsets? popupPadding,
    double? popupMaxWidth,
    double? popupMaxHeight,
    Duration? animationDuration,
    Curve? animationCurve,
    Duration? longPressDuration,
    bool? showHotspotIndicator,
    Color? indicatorColor,
  }) {
    return PdfHotspotStyle(
      highlightColor: highlightColor ?? this.highlightColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      popupBackgroundColor: popupBackgroundColor ?? this.popupBackgroundColor,
      popupTextColor: popupTextColor ?? this.popupTextColor,
      popupShadow: popupShadow ?? this.popupShadow,
      popupPadding: popupPadding ?? this.popupPadding,
      popupMaxWidth: popupMaxWidth ?? this.popupMaxWidth,
      popupMaxHeight: popupMaxHeight ?? this.popupMaxHeight,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      longPressDuration: longPressDuration ?? this.longPressDuration,
      showHotspotIndicator: showHotspotIndicator ?? this.showHotspotIndicator,
      indicatorColor: indicatorColor ?? this.indicatorColor,
    );
  }
}
