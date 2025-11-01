import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/constants/app_colors.dart';

class ScreenPdfViewer extends StatefulWidget {
  final String pdfUrl;
  // final String inspectionId;
  // final String branchName;

  const ScreenPdfViewer({
    Key? key,
    required this.pdfUrl,
    // required this.inspectionId,
    // required this.branchName,
  }) : super(key: key);

  @override
  State<ScreenPdfViewer> createState() => _ScreenPdfViewerState();
}

class _ScreenPdfViewerState extends State<ScreenPdfViewer> {
  // bool _isDownloading = false;
  // double _downloadProgress = 0.0;

  // Future<void> _downloadPDF() async {
  //   try {
  //     setState(() {
  //       _isDownloading = true;
  //       _downloadProgress = 0.0;
  //     });

  //     // Request storage permission
  //     if (Platform.isAndroid) {
  //       var status = await Permission.storage.status;
  //       if (!status.isGranted) {
  //         status = await Permission.storage.request();
  //         if (!status.isGranted) {
  //           throw Exception('Storage permission denied');
  //         }
  //       }
  //     }

  //     // Get download directory
  //     Directory? directory;
  //     if (Platform.isAndroid) {
  //       directory = Directory('/storage/emulated/0/Download');
  //       if (!await directory.exists()) {
  //         directory = await getExternalStorageDirectory();
  //       }
  //     } else {
  //       directory = await getApplicationDocumentsDirectory();
  //     }

  //     // Create filename
  //     final fileName =
  //         'Inspection_${widget.branchName}_${widget.inspectionId}.pdf'
  //             .replaceAll(' ', '_');
  //     final filePath = '${directory!.path}/$fileName';

  //     // Download file
  //     final dio = Dio();
  //     await dio.download(
  //       widget.pdfUrl,
  //       filePath,
  //       onReceiveProgress: (received, total) {
  //         if (total != -1) {
  //           setState(() {
  //             _downloadProgress = received / total;
  //           });
  //         }
  //       },
  //     );

  //     setState(() {
  //       _isDownloading = false;
  //     });

  //     // Show success message
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('PDF downloaded to: ${directory.path}'),
  //           backgroundColor: Colors.green,
  //           duration: const Duration(seconds: 3),
  //           action: SnackBarAction(
  //             label: 'OK',
  //             textColor: Colors.white,
  //             onPressed: () {},
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isDownloading = false;
  //     });

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Download failed: ${e.toString()}'),
  //           backgroundColor: Colors.red,
  //           duration: const Duration(seconds: 3),
  //         ),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(
        title: LocaleKeys.inspection_report.tr(),
        showLang: false,
        showLogout: false,
      ),
      // AppBar(
      //   title: const Text(''),

      //   // actions: [
      //   //   if (_isDownloading)
      //   //     Center(
      //   //       child: Padding(
      //   //         padding: const EdgeInsets.symmetric(horizontal: 16.0),
      //   //         child: SizedBox(
      //   //           width: 24,
      //   //           height: 24,
      //   //           child: CircularProgressIndicator(
      //   //             value: _downloadProgress,
      //   //             strokeWidth: 2,
      //   //             color: Colors.white,
      //   //           ),
      //   //         ),
      //   //       ),
      //   //     )
      //   //   else
      //   //     IconButton(
      //   //       icon: const Icon(Icons.download),
      //   //       onPressed: _downloadPDF,
      //   //       tooltip: 'Download PDF',
      //   //     ),
      //   // ],
      // ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
        onDocumentLoadFailed: (details) {
          showSnakBarr(context, '${LocaleKeys.error.tr()}: ${details.description}');
        },
      ),
    );
  }
}
