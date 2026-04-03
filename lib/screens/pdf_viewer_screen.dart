import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';

class PDFViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PDFViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Share.share("Check out this job notification: $pdfUrl");
            },
          ),
        ],
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        // Loading indicator jab tak PDF load ho
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load PDF: ${details.error}")),
          );
        },
      ),
    );
  }
}