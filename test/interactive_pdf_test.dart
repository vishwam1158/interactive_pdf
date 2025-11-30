import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart' show BoxFit;
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_pdf/interactive_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('PdfHotspotRect', () {
    test('creates rect with correct values', () {
      const rect = PdfHotspotRect(
        left: 100,
        bottom: 200,
        width: 150,
        height: 50,
      );

      expect(rect.left, 100);
      expect(rect.bottom, 200);
      expect(rect.width, 150);
      expect(rect.height, 50);
      expect(rect.right, 250);
      expect(rect.top, 250);
    });

    test('converts to/from PDF rect array', () {
      const rect = PdfHotspotRect(
        left: 100,
        bottom: 200,
        width: 150,
        height: 50,
      );

      final pdfRect = rect.toPdfRect();
      expect(pdfRect, [100, 200, 250, 250]);

      final restored = PdfHotspotRect.fromPdfRect(pdfRect);
      expect(restored, rect);
    });

    test('serializes to/from JSON', () {
      const rect = PdfHotspotRect(
        left: 100,
        bottom: 200,
        width: 150,
        height: 50,
      );

      final json = rect.toJson();
      final restored = PdfHotspotRect.fromJson(json);
      expect(restored, rect);
    });

    test('containsPoint works correctly', () {
      const rect = PdfHotspotRect(
        left: 100,
        bottom: 200,
        width: 100,
        height: 100,
      );

      expect(rect.containsPoint(150, 250), true); // center
      expect(rect.containsPoint(100, 200), true); // bottom-left corner
      expect(rect.containsPoint(200, 300), true); // top-right corner
      expect(rect.containsPoint(50, 250), false); // outside left
      expect(rect.containsPoint(250, 250), false); // outside right
    });
  });

  group('PdfAnnotationContent', () {
    test('creates text content', () {
      final content = PdfAnnotationContent.text(
        'Hello World',
        title: 'Greeting',
      );

      expect(content.text, 'Hello World');
      expect(content.title, 'Greeting');
      expect(content.hasText, true);
      expect(content.hasImage, false);
    });

    test('serializes to/from JSON', () {
      final content = PdfAnnotationContent(
        text: 'Test content',
        title: 'Test Title',
        description: 'Test description',
      );

      final json = content.toJson();
      final restored = PdfAnnotationContent.fromJson(json);

      expect(restored.text, content.text);
      expect(restored.title, content.title);
      expect(restored.description, content.description);
    });
  });

  group('PdfHotspotAnnotation', () {
    test('creates annotation with correct values', () {
      const rect = PdfHotspotRect(
        left: 100,
        bottom: 200,
        width: 150,
        height: 50,
      );

      final annotation = PdfHotspotAnnotation(
        id: 'test-id',
        pageIndex: 0,
        rect: rect,
        type: PdfAnnotationType.text,
        content: PdfAnnotationContent.text('Hidden text'),
      );

      expect(annotation.id, 'test-id');
      expect(annotation.pageIndex, 0);
      expect(annotation.type, PdfAnnotationType.text);
      expect(annotation.content.text, 'Hidden text');
    });

    test('serializes to/from JSON', () {
      const rect = PdfHotspotRect(
        left: 100,
        bottom: 200,
        width: 150,
        height: 50,
      );

      final annotation = PdfHotspotAnnotation(
        id: 'test-id',
        pageIndex: 1,
        rect: rect,
        type: PdfAnnotationType.text,
        content: PdfAnnotationContent.text('Test', title: 'Title'),
        label: 'My Label',
      );

      final json = annotation.toJson();
      final restored = PdfHotspotAnnotation.fromJson(json);

      expect(restored.id, annotation.id);
      expect(restored.pageIndex, annotation.pageIndex);
      expect(restored.type, annotation.type);
      expect(restored.label, annotation.label);
    });
  });

  group('PdfAnnotationManifest', () {
    test('creates empty manifest', () {
      final manifest = PdfAnnotationManifest.empty();

      expect(manifest.annotations, isEmpty);
      expect(manifest.sharedAssets, isEmpty);
      expect(manifest.version, PdfAnnotationManifest.currentVersion);
    });

    test('adds annotations and assets', () {
      var manifest = PdfAnnotationManifest.empty();

      final annotation = PdfHotspotAnnotation(
        id: 'test-1',
        pageIndex: 0,
        rect: const PdfHotspotRect(left: 0, bottom: 0, width: 100, height: 100),
        type: PdfAnnotationType.text,
        content: PdfAnnotationContent.text('Test'),
      );

      manifest = manifest.addAnnotation(annotation);
      expect(manifest.annotations.length, 1);

      manifest = manifest.addAsset('key1', Uint8List.fromList([1, 2, 3, 4]));
      expect(manifest.hasAsset('key1'), true);
    });

    test('serializes to/from JSON string', () {
      final annotation = PdfHotspotAnnotation(
        id: 'test-1',
        pageIndex: 0,
        rect: const PdfHotspotRect(left: 0, bottom: 0, width: 100, height: 100),
        type: PdfAnnotationType.text,
        content: PdfAnnotationContent.text('Test'),
      );

      final manifest = PdfAnnotationManifest(
        id: 'manifest-1',
        annotations: [annotation],
      );

      final json = manifest.toJsonString();
      final restored = PdfAnnotationManifest.fromJsonString(json);

      expect(restored.id, manifest.id);
      expect(restored.annotations.length, 1);
      expect(restored.annotations.first.id, 'test-1');
    });
  });

  group('AdvancePdfDocument', () {
    test('creates document and adds page', () {
      final doc = AdvancePdfDocument(
        title: 'Test Document',
        author: 'Test Author',
      );

      final pageIndex = doc.addPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(child: pw.Text('Hello World')),
      );

      expect(pageIndex, 0);
      expect(doc.pageCount, 1);
    });

    test('adds hotspot annotations', () {
      final doc = AdvancePdfDocument();

      doc.addPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Text('Page 1'),
      );

      final hotspot = doc.addTextHotspot(
        pageIndex: 0,
        rect: const PdfHotspotRect(
          left: 100,
          bottom: 700,
          width: 200,
          height: 50,
        ),
        text: 'Hidden text content',
        title: 'Secret Info',
      );

      expect(doc.hotspots.length, 1);
      expect(hotspot.type, PdfAnnotationType.text);
      expect(hotspot.content.text, 'Hidden text content');
    });

    test('removes and updates hotspots', () {
      final doc = AdvancePdfDocument();

      doc.addPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Text('Page 1'),
      );

      final hotspot = doc.addTextHotspot(
        pageIndex: 0,
        rect: const PdfHotspotRect(
          left: 100,
          bottom: 700,
          width: 200,
          height: 50,
        ),
        text: 'Original text',
      );

      expect(doc.hotspots.length, 1);

      // Update
      final updated = hotspot.copyWith(
        content: PdfAnnotationContent.text('Updated text'),
      );
      doc.updateHotspot(updated);
      expect(doc.hotspots.first.content.text, 'Updated text');

      // Remove
      doc.removeHotspot(hotspot.id);
      expect(doc.hotspots.length, 0);
    });

    test('saves document to bytes', () async {
      final doc = AdvancePdfDocument();

      doc.addPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(child: pw.Text('Test Document')),
      );

      doc.addTextHotspot(
        pageIndex: 0,
        rect: const PdfHotspotRect(
          left: 100,
          bottom: 700,
          width: 200,
          height: 50,
        ),
        text: 'Hidden info',
      );

      final bytes = await doc.save();

      expect(bytes.isNotEmpty, true);
      // PDF files start with %PDF
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });

  group('PdfCoordinateMapper', () {
    test('converts PDF rect to Flutter rect', () {
      const pdfRect = PdfHotspotRect(
        left: 100,
        bottom: 700,
        width: 200,
        height: 50,
      );

      const pageSizeInPoints = Size(595, 842); // A4
      const renderedPageSize = Size(297.5, 421); // Half size

      final flutterRect = PdfCoordinateMapper.toFlutterRect(
        pdfRect: pdfRect,
        pageSizeInPoints: pageSizeInPoints,
        renderedPageSize: renderedPageSize,
      );

      // At half scale, coordinates should be halved
      // PDF bottom 700 → Flutter top = (842 - 750) * 0.5 = 46
      expect(flutterRect.left, 50); // 100 * 0.5
      expect(flutterRect.width, 100); // 200 * 0.5
      expect(flutterRect.height, 25); // 50 * 0.5
    });

    test('calculates fit size with contain', () {
      const pageSize = Size(595, 842); // A4 portrait
      const constraints = Size(400, 600);

      final fitSize = PdfCoordinateMapper.calculateFitSize(
        pageSizeInPoints: pageSize,
        constraints: constraints,
        fit: BoxFit.contain,
      );

      // Page aspect = 595/842 ≈ 0.707
      // Constraints aspect = 400/600 ≈ 0.667
      // Page aspect > constraint aspect → page is wider, fit to width
      expect(fitSize.width, 400);
      expect(fitSize.height, closeTo(566.0, 1.0)); // 400 / 0.707
    });
  });

  group('PdfHotspotStyle', () {
    test('default light style has expected values', () {
      const style = PdfHotspotStyle.light;

      expect(style.borderRadius, 4.0);
      expect(style.showHotspotIndicator, false);
    });

    test('copyWith creates modified copy', () {
      const style = PdfHotspotStyle.light;
      final modified = style.copyWith(
        borderRadius: 8.0,
        showHotspotIndicator: true,
      );

      expect(modified.borderRadius, 8.0);
      expect(modified.showHotspotIndicator, true);
      // Unchanged values
      expect(modified.borderWidth, style.borderWidth);
    });
  });
}
