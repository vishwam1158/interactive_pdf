// ignore_for_file: avoid_print
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:advance_pdf_genrator/advance_pdf_genrator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advance PDF Generator Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _pdfBytes;
  bool _isGenerating = false;
  final PdfInteractiveController _controller = PdfInteractiveController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Create document
      final doc = AdvancePdfDocument(
        title: 'Interactive PDF Demo',
        author: 'Advance PDF Generator',
      );

      // Add first page with content and hotspots
      doc.addPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Interactive PDF Document',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'This PDF contains hidden hotspots that reveal additional '
                'information when you long-press on them in the interactive viewer.',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 40),

              // Hotspot area 1
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Icon(
                          const pw.IconData(0xe88e), // info icon
                          color: PdfColors.blue700,
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'Hold to reveal secret information',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Long press on this area to see hidden content.',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.blue700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Hotspot area 2
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.green200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Icon(
                          const pw.IconData(0xe8b8), // lightbulb icon
                          color: PdfColors.green700,
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'Tip: Interactive Elements',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'This box contains a hidden tip. Long press to reveal!',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Table with hotspots
              pw.Text(
                'Data Table with Hidden Details',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _tableCell('Product', isHeader: true),
                      _tableCell('Price', isHeader: true),
                      _tableCell('Stock', isHeader: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Widget A'),
                      _tableCell('\$29.99'),
                      _tableCell('In Stock'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Widget B'),
                      _tableCell('\$49.99'),
                      _tableCell('Limited'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('Widget C'),
                      _tableCell('\$19.99'),
                      _tableCell('Out of Stock'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      // Add hotspot for the blue info box
      // Position approximately where the blue box is on A4 page
      doc.addTextHotspot(
        pageIndex: 0,
        rect: const PdfHotspotRect(
          left: 40,
          bottom: 582, // A4 height - top margin - content offset
          width: 515,
          height: 90,
        ),
        title: '🔐 Secret Information',
        text:
            'This is the hidden content that only appears when you '
            'long-press on the hotspot area in the interactive viewer!\n\n'
            'The PDF remains valid in any viewer, but the interactive '
            'features only work with this package.',
      );

      // Add hotspot for the green tip box
      doc.addTextHotspot(
        pageIndex: 0,
        rect: const PdfHotspotRect(
          left: 40,
          bottom: 462,
          width: 515,
          height: 90,
        ),
        title: '💡 Pro Tip',
        text:
            'You can add hotspots to any region of your PDF!\n\n'
            '• Text hotspots for additional explanations\n'
            '• Image hotspots for hidden diagrams or photos\n'
            '• Custom hotspots for any data you need',
      );

      // Add hotspot for table row
      doc.addTextHotspot(
        pageIndex: 0,
        rect: const PdfHotspotRect(
          left: 40,
          bottom: 368,
          width: 515,
          height: 25,
        ),
        title: 'Widget A Details',
        text:
            'SKU: WDG-001-A\n'
            'Manufacturer: ACME Corp\n'
            'Weight: 0.5 kg\n'
            'Dimensions: 10x10x5 cm\n'
            'Last restocked: 2024-01-15',
      );

      // Add second page
      doc.addPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Page 2: More Examples',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                height: 200,
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple50,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.purple200, width: 2),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Long press for image preview',
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.purple700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Add a text hotspot on page 2
      doc.addTextHotspot(
        pageIndex: 1,
        rect: const PdfHotspotRect(
          left: 40,
          bottom: 560,
          width: 515,
          height: 200,
        ),
        title: '🖼️ Image Preview',
        text:
            'In a real application, you could embed an actual image here!\n\n'
            'Use doc.addImageHotspot() with image bytes to add '
            'hidden images that appear on long-press.',
      );

      // Save the PDF
      final bytes = await doc.save();

      setState(() {
        _pdfBytes = bytes;
        _isGenerating = false;
      });

      // Initialize controller with the PDF
      await _controller.initialize(pdfBytes: bytes);
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _savePdf() async {
    if (_pdfBytes == null) return;

    try {
      // Use platform-safe file saving
      final savedPath = await saveToFile('interactive_demo.pdf', _pdfBytes!);

      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isWeb
                    ? 'PDF downloaded to browser downloads'
                    : 'PDF saved to: $savedPath',
              ),
              action: isWeb
                  ? null
                  : SnackBarAction(
                      label: 'Copy Path',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: savedPath));
                      },
                    ),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not save PDF')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance PDF Generator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePdf,
              tooltip: 'Save PDF',
            ),
        ],
      ),
      body: _pdfBytes == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Generate an Interactive PDF',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Long-press on hotspots to reveal hidden content',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generatePdf,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      _isGenerating ? 'Generating...' : 'Generate PDF',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Info bar
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Long-press on highlighted areas to reveal hidden content',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _pdfBytes = null;
                          });
                        },
                        child: const Text('New PDF'),
                      ),
                    ],
                  ),
                ),
                // PDF Preview
                Expanded(
                  child: PdfInteractivePreview(
                    pdfBytes: _pdfBytes!,
                    controller: _controller,
                    style: PdfHotspotStyle.withIndicators.copyWith(
                      indicatorColor: Colors.blue.withOpacity(0.15),
                      highlightColor: Colors.blue.withOpacity(0.25),
                    ),
                    onHotspotActivated: (annotation) {
                      print('Hotspot activated: ${annotation.id}');
                    },
                    onHotspotDismissed: (annotation) {
                      print('Hotspot dismissed: ${annotation.id}');
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
