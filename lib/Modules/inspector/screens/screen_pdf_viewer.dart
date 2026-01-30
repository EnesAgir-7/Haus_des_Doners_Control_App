import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/constants/app_colors.dart';

class ScreenPdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String inspectionId;
  final String branchName;

  const ScreenPdfViewer({
    Key? key,
    required this.pdfUrl,
    required this.inspectionId,
    required this.branchName,
  }) : super(key: key);

  @override
  State<ScreenPdfViewer> createState() => _ScreenPdfViewerState();
}

class _ScreenPdfViewerState extends State<ScreenPdfViewer> {
  bool _isDownloading = false;

  Future<void> _downloadPDF() async {
    try {
      setState(() {
        _isDownloading = true;
      });

      // Download bytes first to have them ready
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode != 200) throw Exception('Failed to download PDF');
      final bytes = response.bodyBytes;

      // Request storage permission for Android
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        bool hasPermission = false;

        if (sdkInt >= 33) {
          // Android 13+ doesn't use the generic STORAGE permission for non-media files.
          // We can try to write directly, or just fallback to share sheet if it fails.
          // For now, we'll assume we can try to save or just use the share/save-to-files flow.
          hasPermission = true;
        } else {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          hasPermission = status.isGranted;
        }

        if (!hasPermission && mounted) {
          showSnakBarr(
            context,
            'Storage permission denied. Opening share options...',
          );
          // Fallback to sharing which allows saving
          await _sharePDF(bytes: bytes);
          return;
        }
      }

      // Get directory
      Directory? directory;
      if (Platform.isAndroid) {
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }

          final fileName =
              'Report_${widget.branchName}_${widget.inspectionId}.pdf'
                  .replaceAll(' ', '_');
          final filePath = '${directory!.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(bytes);

          setState(() => _isDownloading = false);

          if (mounted) {
            showSnakBarr(context, 'PDF saved to: ${directory.path}');
          }
          return;
        } catch (e) {
          debugPrint('Direct save failed: $e. Falling back to share sheet...');
          // Fallback to share sheet if direct save fails (common on Android 11+ Scoped Storage)
          await _sharePDF(bytes: bytes);
          return;
        }
      } else {
        // iOS handled via share sheet
        await _sharePDF(bytes: bytes);
        return;
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        showSnakBarr(context, 'Download failed: ${e.toString()}');
      }
    }
  }

  Future<void> _sharePDF({List<int>? bytes}) async {
    try {
      setState(() {
        _isDownloading = true; // Use same loading state
      });

      final fileBytes =
          bytes ?? (await http.get(Uri.parse(widget.pdfUrl))).bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final fileName = 'Report_${widget.branchName}_${widget.inspectionId}.pdf'
          .replaceAll(' ', '_');
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(fileBytes);

      setState(() => _isDownloading = false);

      await SharePlus.instance.share(
        ShareParams(
          uri: Uri.file(file.path),
          text: 'Inspection Report: ${widget.branchName}',
          title: 'Inspection Report - ${widget.branchName}',
        ),
      );
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        showSnakBarr(context, 'Sharing failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(
        title: LocaleKeys.inspection_report.tr(),
        actions: [
          if (_isDownloading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadPDF,
              tooltip: 'Download',
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _sharePDF,
              tooltip: 'Share',
            ),
          ],
        ],
      ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
        onDocumentLoadFailed: (details) {
          showSnakBarr(
            context,
            '${LocaleKeys.error.tr()}: ${details.description}',
          );
        },
      ),
    );
  }
}
