# Interactive PDF

A Flutter package for generating PDFs with **interactive hotspot annotations** that reveal embedded text or images on long-press. The annotations are stored persistently in the PDF and work across sharing and reopening.

## ✨ Features

- 🎯 **Interactive Hotspots** - Define regions that reveal hidden content on long-press
- 📝 **Text & Image Annotations** - Embed text, images, or custom data
- 💾 **Persistent Storage** - Annotations are stored inside the PDF file
- 🔄 **Share & Reopen** - Works after sharing or reopening the PDF
- 📱 **Cross-Platform** - Works on iOS, Android, Web, macOS, Windows, and Linux
- 🎨 **Customizable Styling** - Full control over hotspot appearance and overlays
- ⚡ **Performance Optimized** - LRU caching, pre-rendering, and efficient memory management
- 📄 **Standard PDF Compatibility** - PDFs remain valid in any PDF viewer

## 🌍 Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| iOS      | ✅        | Full support |
| Android  | ✅        | Full support |
| Web      | ✅        | File download via browser |
| macOS    | ✅        | Full support |
| Windows  | ✅        | Full support |
| Linux    | ✅        | Full support |

### Platform-specific File Saving

```dart
import 'package:interactive_pdf/interactive_pdf.dart';

// Save PDF bytes - works on all platforms
final bytes = await doc.save();

// Save to file - platform-aware
if (!isWeb) {
  // Native platforms: saves to specified path
  await doc.saveToFile('/path/to/file.pdf');
} else {
  // Web: triggers browser download
  await saveToFile('document.pdf', bytes);
}

// Check platform
if (isWeb) {
  // Running on web
} else if (isMobile) {
  // Running on iOS or Android
} else if (isDesktop) {
  // Running on macOS, Windows, or Linux
}
```

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  interactive_pdf: ^0.1.0
```

## 🚀 Quick Start

### Creating an Interactive PDF

```dart
import 'package:interactive_pdf/interactive_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Create document
final doc = AdvancePdfDocument(
  title: 'My Interactive PDF',
  author: 'Your Name',
);

// Add a page
doc.addPage(
  pageFormat: PdfPageFormat.a4,
  build: (context) => pw.Center(
    child: pw.Text('Hello World!'),
  ),
);

// Add a text hotspot
doc.addTextHotspot(
  pageIndex: 0,
  rect: const PdfHotspotRect(
    left: 100,
    bottom: 700,
    width: 200,
    height: 50,
  ),
  text: 'This is hidden text that appears on long-press!',
  title: 'Secret Info',
);

// Save PDF
final bytes = await doc.save();
```

### Previewing with Interactive Hotspots

```dart
import 'package:flutter/material.dart';
import 'package:interactive_pdf/interactive_pdf.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const PdfPreviewScreen({required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Preview')),
      body: PdfInteractivePreview(
        pdfBytes: pdfBytes,
        style: PdfHotspotStyle.withIndicators,
        onHotspotActivated: (annotation) {
          print('Hotspot activated: ${annotation.id}');
        },
      ),
    );
  }
}
```

## 📚 API Reference

### AdvancePdfDocument

The main class for creating PDFs with hotspot support.

```dart
final doc = AdvancePdfDocument(
  title: 'Document Title',
  author: 'Author Name',
  subject: 'Subject',
  keywords: ['flutter', 'pdf'],
);

// Add pages
int pageIndex = doc.addPage(
  pageFormat: PdfPageFormat.a4,
  build: (context) => pw.Text('Content'),
);

// Add hotspots
doc.addTextHotspot(
  pageIndex: 0,
  rect: PdfHotspotRect(...),
  text: 'Hidden text',
);

doc.addImageHotspot(
  pageIndex: 0,
  rect: PdfHotspotRect(...),
  imageBytes: myImageBytes,
);

// Generic hotspot
doc.addHotspot(
  pageIndex: 0,
  rect: PdfHotspotRect(...),
  type: PdfAnnotationType.custom,
  content: PdfAnnotationContent(
    text: 'Text',
    customPayload: {'key': 'value'},
  ),
);

// Save
final bytes = await doc.save();
await doc.saveToFile('/path/to/file.pdf');
```

### PdfHotspotRect

Defines a rectangular region in PDF coordinates (points, 1/72 inch).

```dart
// Basic constructor
const rect = PdfHotspotRect(
  left: 100,    // X from left edge
  bottom: 200,  // Y from bottom (PDF uses bottom-left origin)
  width: 150,
  height: 50,
);

// From corners
final rect = PdfHotspotRect.fromLTRB(left, bottom, right, top);

// From Flutter Rect (with coordinate conversion)
final rect = PdfHotspotRect.fromFlutterRect(flutterRect, pageHeight);
```

### PdfAnnotationContent

Content payload for hotspot annotations.

```dart
// Text content
final content = PdfAnnotationContent.text(
  'Hidden message',
  title: 'Title',
);

// Image content
final content = PdfAnnotationContent.image(
  imageBytes,
  title: 'Hidden Image',
);

// Full constructor
final content = PdfAnnotationContent(
  text: 'Description',
  imageBytes: imageData,
  title: 'Title',
  description: 'Subtitle',
  customPayload: {'extra': 'data'},
);
```

### PdfInteractivePreview

Widget for displaying PDFs with interactive hotspot support.

```dart
PdfInteractivePreview(
  pdfBytes: pdfBytes,
  
  // Optional: Pre-parsed hotspots (auto-parsed if null)
  hotspots: myHotspots,
  
  // Callbacks
  onHotspotActivated: (annotation) { },
  onHotspotDismissed: (annotation) { },
  onPageChanged: (page) { },
  
  // Customization
  style: PdfHotspotStyle.light,
  overlayBuilder: (context, annotation) => MyCustomOverlay(),
  
  // Behavior
  enableZoom: true,
  enablePageNavigation: true,
  showPageNumbers: true,
  
  // Display
  backgroundColor: Colors.grey,
  pagePadding: EdgeInsets.all(8),
  minScale: 1.0,
  maxScale: 4.0,
  renderDpi: 150,
  
  // External controller
  controller: myController,
)
```

### PdfInteractiveController

Programmatic control over the preview widget.

```dart
final controller = PdfInteractiveController();

// Initialize with PDF
await controller.initialize(pdfBytes: bytes);

// Navigation
controller.jumpToPage(2);
controller.nextPage();
controller.previousPage();

// Hotspot control
controller.showHotspot('hotspot-id');
controller.hideHotspot();

// Zoom
controller.setScale(2.0);
controller.resetZoom();

// Properties
int currentPage = controller.currentPage;
int pageCount = controller.pageCount;
List<PdfHotspotAnnotation> hotspots = controller.hotspots;

// Clean up
controller.dispose();
```

### PdfHotspotStyle

Customize the visual appearance of hotspots and overlays.

```dart
// Preset styles
PdfHotspotStyle.light      // Default light theme
PdfHotspotStyle.dark       // Dark theme
PdfHotspotStyle.minimal    // No visual indicators
PdfHotspotStyle.withIndicators  // Visible hotspot regions

// Custom style
final style = PdfHotspotStyle(
  highlightColor: Colors.blue.withOpacity(0.3),
  borderRadius: 8.0,
  borderWidth: 2.0,
  borderColor: Colors.blue,
  popupBackgroundColor: Colors.white,
  popupTextColor: Colors.black87,
  popupMaxWidth: 300,
  popupMaxHeight: 400,
  animationDuration: Duration(milliseconds: 200),
  longPressDuration: Duration(milliseconds: 500),
  showHotspotIndicator: true,
  indicatorColor: Colors.blue.withOpacity(0.2),
);

// Modify existing style
final modified = PdfHotspotStyle.light.copyWith(
  borderRadius: 12.0,
  showHotspotIndicator: true,
);
```

### AdvancePdfParser

Parse existing PDFs to extract hotspot annotations.

```dart
// Parse hotspots from PDF bytes
final hotspots = await AdvancePdfParser.parseHotspots(pdfBytes);

// Get full manifest
final manifest = await AdvancePdfParser.parseManifest(pdfBytes);

// Check if PDF has hotspots
final hasHotspots = await AdvancePdfParser.hasHotspots(pdfBytes);

// Get page dimensions
final dimensions = await AdvancePdfParser.getPageDimensions(pdfBytes);
```

## 🎨 Custom Overlay Builder

Create custom UI for displaying annotation content:

```dart
PdfInteractivePreview(
  pdfBytes: pdfBytes,
  overlayBuilder: (context, annotation) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (annotation.content.title != null)
              Text(
                annotation.content.title!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            if (annotation.content.imageBytes != null)
              Image.memory(annotation.content.imageBytes!),
            if (annotation.content.text != null)
              Text(annotation.content.text!),
          ],
        ),
      ),
    );
  },
)
```

## ⚡ Performance Tips

1. **Use appropriate DPI**: Lower `renderDpi` (100-150) for faster rendering, higher (200-300) for print quality
2. **Pre-render pages**: The preview automatically pre-renders adjacent pages
3. **Reuse controllers**: Create controller once and reuse across rebuilds
4. **Optimize images**: Compress image hotspots before embedding
5. **Use shared assets**: For repeated images, use `addSharedAsset()` and reference by key

## 🔧 How It Works

1. **Storage**: Hotspot data is stored as PDF annotations with custom `/APDF_Hotspot` dictionaries plus an embedded JSON manifest
2. **Compatibility**: The PDF remains valid in any viewer; custom data is simply ignored by standard viewers
3. **Parsing**: When reopening, the manifest is extracted and hotspots are reconstructed
4. **Rendering**: Pages are rasterized using the `printing` package with LRU caching
5. **Interaction**: Long-press gesture detection with coordinate mapping between PDF and Flutter spaces

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

