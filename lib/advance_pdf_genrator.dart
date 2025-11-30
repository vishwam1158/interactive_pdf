/// Advanced PDF Generator with Interactive Hotspot Annotations
///
/// A Flutter package for generating PDFs with interactive hotspot regions
/// that reveal embedded text or images on long-press. The annotations are
/// stored persistently in the PDF and work across sharing and reopening.
library advance_pdf_genrator;

// Core exports
export 'src/models/models.dart';
export 'src/document/advance_pdf_document.dart';
export 'src/preview/pdf_interactive_preview.dart';
export 'src/preview/pdf_interactive_controller.dart';
export 'src/parser/advance_pdf_parser.dart';
export 'src/utils/pdf_coordinate_mapper.dart';
export 'src/utils/hotspot_style.dart';
export 'src/utils/platform_utils.dart'
    show isWeb, isMobile, isDesktop, saveToFile, getTempDirectoryPath;

// Re-export commonly used pdf package types for convenience
// Note: We only export non-conflicting types. For TextStyle and Font,
// use pw.TextStyle and pw.Font with 'import package:pdf/widgets.dart as pw;'
export 'package:pdf/pdf.dart' show PdfPageFormat, PdfColor;
export 'package:pdf/widgets.dart' show PageTheme;
