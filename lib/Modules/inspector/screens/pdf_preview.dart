import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_colors.dart';
import '../widgets/custom_toast.dart';

class PDFPreviewScreen extends StatelessWidget {
  final pw.Document pdf;
  final String branchName;

  const PDFPreviewScreen({
    super.key,
    required this.pdf,
    required this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PDF Preview - $branchName',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.share, color: Colors.white),
          //   onPressed: () => _sharePDF(),
          // ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadPDF(context),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdf.save(),
        allowSharing: true,
        allowPrinting: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'inspection_${branchName.replaceAll(' ', '_')}.pdf',
        actionBarTheme: PdfActionBarTheme(
          backgroundColor: AppColors.primaryRed,
        ),
      ),
    );
  }

  // Future<void> _sharePDF() async {
  //   await Printing.sharePdf(
  //     bytes: await pdf.save(),
  //     filename: 'inspection_${branchName.replaceAll(' ', '_')}.pdf',
  //   );
  // }

  Future<void> _downloadPDF(BuildContext context) async {
    try {
      // Request appropriate permissions based on Android version
      bool hasPermission = false;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ doesn't need storage permission for Downloads
          hasPermission = true;
        } else if (androidInfo.version.sdkInt >= 30) {
          // Android 11 & 12
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
          }
          hasPermission = status.isGranted;
        } else {
          // Android 10 and below
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          hasPermission = status.isGranted;
        }

        if (!hasPermission) {
          if (context.mounted) {
            showSnakBarr(context, 'Storage permission denied');
          }
          return;
        }
      }

      final bytes = await pdf.save();
      String filePath;

      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        filePath =
            '${downloadsDir.path}/Inspection_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        filePath =
            '${dir.path}/Inspection_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        showSnakBarr(context, 'PDF saved to Downloads');
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        showSnakBarr(context, 'Error: $e');
      }
    }
  }
}
