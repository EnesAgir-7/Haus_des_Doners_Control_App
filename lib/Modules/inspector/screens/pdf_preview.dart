import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../widgets/custom_app_bar.dart';

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
      appBar: CustomAppBar(
        title: '${LocaleKeys.pdfPreview.tr()} - $branchName',

        actions: [
          // IconButton(
          //   icon: const Icon(Icons.share, color: Colors.white),
          //   onPressed: () => _sharePDF(),
          // ),
          // Removed download button per user request for preview
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
        actionBarTheme: const PdfActionBarTheme(
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

  // Removed unused _downloadPDF method per user request to disable downloading in preview
}
