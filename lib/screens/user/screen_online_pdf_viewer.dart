import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String inspectorName;

  const PdfViewerScreen({
    Key? key,
    required this.pdfUrl,
    required this.inspectorName,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool isDownloading = false;

  Future<void> _downloadPdf() async {
    try {
      setState(() => isDownloading = true);

      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF');
      }

      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'inspection_report_${widget.inspectorName}_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes, flush: true);

      setState(() => isDownloading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF downloaded successfully to ${dir.path}")),
        );
      }
    } catch (e) {
      setState(() => isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to download: $e")));
      }
      debugPrint('Error downloading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inspection Report - ${widget.inspectorName}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: isDownloading ? null : _downloadPdf,
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: SafeArea(
        child: SfPdfViewer.network(
          widget.pdfUrl,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          onDocumentLoadFailed: (details) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(details.error.toString())));
          },
        ),
      ),
    );
  }
}

// class PdfViewerScreen extends StatefulWidget {
//   final String pdfUrl;
//   final String inspectorName;

//   const PdfViewerScreen({
//     Key? key,
//     required this.pdfUrl,
//     required this.inspectorName,
//   }) : super(key: key);

//   @override
//   State<PdfViewerScreen> createState() => _PdfViewerScreenState();
// }

// class _PdfViewerScreenState extends State<PdfViewerScreen> {
//   bool _isLoading = true;

//   @override
//   Widget build(BuildContext context) {
//     final pdfViewerUrl =
//         'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.pdfUrl)}';

//     return Scaffold(
//       appBar: AppBar(title: Text("${widget.inspectorName}'s Report")),
//       body: Stack(
//         children: [
//           WebViewWidget(
//             controller: WebViewController()
//               ..setJavaScriptMode(JavaScriptMode.unrestricted)
//               ..setNavigationDelegate(
//                 NavigationDelegate(
//                   onPageFinished: (_) => setState(() => _isLoading = false),
//                 ),
//               )
//               ..loadRequest(Uri.parse(pdfViewerUrl)),
//           ),
//           if (_isLoading) const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }
// }
