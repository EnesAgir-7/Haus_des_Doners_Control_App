import 'dart:io';
import 'package:csv/csv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inspection_model.dart';
import 'package:intl/intl.dart';

class CsvExportService {
  /// Converts a list of inspections to a detailed CSV format and shares it.
  /// Also attempts to save it to the public Downloads folder on Android.
  static Future<void> exportInspections({
    required List<InspectionModel> inspections,
    required String fileNamePrefix,
    required String shareTitle,
    required String inspectorName,
    required int month,
    required int year,
  }) async {
    try {
      // 1. Generate CSV data
      List<List<dynamic>> rows = _generateInspectionRows(
        inspections: inspections,
        inspectorName: inspectorName,
        month: month,
        year: year,
      );
      String csvContent = const ListToCsvConverter().convert(rows);

      // 2. Determine file name
      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final String fileName = '${fileNamePrefix}_$timestamp.csv'.replaceAll(
        ' ',
        '_',
      );

      // 3. Save and Share
      await _saveAndShareFile(
        content: csvContent,
        fileName: fileName,
        shareTitle: shareTitle,
      );
    } catch (e) {
      debugPrint('CSV Export Error: $e');
      rethrow;
    }
  }

  static List<List<dynamic>> _generateInspectionRows({
    required List<InspectionModel> inspections,
    required String inspectorName,
    required int month,
    required int year,
  }) {
    if (inspections.isEmpty) return [];

    // Collect all unique category names to create columns
    Set<String> categoryNames = {};
    for (var inspection in inspections) {
      categoryNames.addAll(inspection.categories.keys);
    }
    List<String> sortedCategories = categoryNames.toList()..sort();

    // 1. Inspector Info Header Section
    List<List<dynamic>> rows = [
      ['INSPECTOR REPORT', ''],
      ['Inspector Name:', inspectorName],
      ['Total Inspections:', inspections.length],
      ['Month:', month],
      ['Year:', year],
      ['Generated At:', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
      [], // Empty row for spacing
    ];

    // 2. Table Headers
    List<dynamic> tableHeader = [
      'Branch Name',
      'Status',
      'Scheduled Time',
      'Completed Time',
      'Overall Score',
      'Representative Name',
      'Overall Notes',
      'Created At',
    ];

    // Add category columns
    for (var catName in sortedCategories) {
      tableHeader.add('$catName Score');
      tableHeader.add('$catName Notes');
    }

    // Move PDF URL to the very end
    tableHeader.add('PDF Report URL');

    rows.add(tableHeader);

    // 3. Data rows
    for (var inspection in inspections) {
      // Fix Score formatting to prevent Excel date conversion (e.g., "10/12" -> " 10/12")
      String formattedOverallScore = inspection.score.contains('/')
          ? ' ${inspection.score}'
          : inspection.score;

      List<dynamic> row = [
        inspection.branchName,
        inspection.status,
        inspection.scheduledTime,
        inspection.completedTime != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(inspection.completedTime!)
            : '',
        formattedOverallScore,
        inspection.branchRepresentativeName ?? '',
        inspection.overallNotes,
        DateFormat('yyyy-MM-dd HH:mm').format(inspection.createdAt),
      ];

      // Add scores and notes for each category
      for (var catName in sortedCategories) {
        final categoryData = inspection.categories[catName];
        if (categoryData != null) {
          // Also fix category scores
          String formattedCatScore = categoryData.score.contains('/')
              ? ' ${categoryData.score}'
              : categoryData.score;
          row.add(formattedCatScore);
          row.add(categoryData.notes);
        } else {
          row.add('N/A');
          row.add('');
        }
      }

      // Add PDF URL at the end
      row.add(inspection.pdfReportUrl ?? '');

      rows.add(row);
    }

    return rows;
  }

  static Future<void> _saveAndShareFile({
    required String content,
    required String fileName,
    required String shareTitle,
  }) async {
    // 1. Request permission for Android
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt < 33) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        if (!status.isGranted) {
          // Fallback to caching and sharing if permission denied
          await _shareOnly(content, fileName, shareTitle);
          return;
        }
      }
    }

    // 2. Attempt to save to public folder on Android
    File? savedFile;
    if (Platform.isAndroid) {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final filePath = '${downloadDir.path}/$fileName';
          savedFile = File(filePath);
          await savedFile.writeAsString(content);
          debugPrint('Saved to Downloads: $filePath');
        }
      } catch (e) {
        debugPrint('Direct save to Downloads failed: $e');
      }
    }

    // 3. Always save to temp location and share (useful for iOS and as fallback)
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsString(content);

    // 4. Open share sheet
    await Share.shareXFiles(
      [XFile(tempFile.path)],
      text: shareTitle,
      subject: shareTitle,
    );
  }

  static Future<void> _shareOnly(
    String content,
    String fileName,
    String shareTitle,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsString(content);

    await Share.shareXFiles(
      [XFile(tempFile.path)],
      text: shareTitle,
      subject: shareTitle,
    );
  }
}
