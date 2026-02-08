import 'dart:io';
import 'package:excel/excel.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inspection_model.dart';
import 'package:intl/intl.dart';
import '../helpers/app_helpers.dart';

class ExcelExportService {
  /// Converts a list of inspections to a beautified Excel format and shares it.
  static Future<void> exportInspections({
    required List<InspectionModel> inspections,
    required String fileNamePrefix,
    required String shareTitle,
    required String inspectorName,
    String? period, // Changed from int month, int year
  }) async {
    try {
      // 1. Create Excel workbook
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      // 2. Define Styles
      CellStyle headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#BFC9D2'),
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      CellStyle titleStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      CellStyle infoLabelStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      // 3. Add Header Section
      _addCell(sheet, 0, 0, 'INSPECTOR REPORT', style: titleStyle);

      _addCell(sheet, 0, 1, 'Inspector Name:', style: infoLabelStyle);
      _addCell(sheet, 1, 1, inspectorName);

      _addCell(sheet, 0, 2, 'Total Inspections:', style: infoLabelStyle);
      _addCell(sheet, 1, 2, inspections.length);

      _addCell(sheet, 0, 3, 'Period:', style: infoLabelStyle);
      _addCell(sheet, 1, 3, period ?? 'All Time');

      _addCell(sheet, 0, 5, 'Generated At:', style: infoLabelStyle);
      _addCell(
        sheet,
        1,
        5,
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      );

      // Spacer row
      int currentRow = 7;

      // 4. Collect Category Columns
      Set<String> categoryNames = {};
      for (var inspection in inspections) {
        categoryNames.addAll(inspection.categories.keys);
      }
      List<String> sortedCategories = categoryNames.toList()..sort();

      // 5. Build Table Headers
      List<String> tableHeaders = [
        'Branch Name',
        'Status',
        'Scheduled Time',
        'Completed Time',
        'Overall Score',
        'Representative Name',
        'Overall Notes',
        'Created At',
      ];

      for (var catName in sortedCategories) {
        tableHeaders.add('$catName Score');
        tableHeaders.add('$catName Notes');
      }
      tableHeaders.add('PDF Report URL');

      for (int i = 0; i < tableHeaders.length; i++) {
        _addCell(sheet, i, currentRow, tableHeaders[i], style: headerStyle);
      }
      currentRow++;

      // 6. Add Data Rows
      for (var inspection in inspections) {
        // Fix Score formatting to prevent Excel date conversion
        String formattedOverallScore = inspection.score.contains('/')
            ? ' ${inspection.score}'
            : inspection.score;

        List<dynamic> rowValues = [
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

        for (var catName in sortedCategories) {
          final categoryData = inspection.categories[catName];
          if (categoryData != null) {
            String formattedCatScore = categoryData.score.contains('/')
                ? ' ${categoryData.score}'
                : categoryData.score;
            rowValues.add(formattedCatScore);
            rowValues.add(categoryData.notes);
          } else {
            rowValues.add('N/A');
            rowValues.add('');
          }
        }
        rowValues.add(inspection.pdfReportUrl ?? '');

        for (int i = 0; i < rowValues.length; i++) {
          _addCell(sheet, i, currentRow, rowValues[i]);
        }
        currentRow++;
      }

      // 7. Save and Share
      final List<int>? fileBytes = excel.save();
      if (fileBytes == null)
        throw Exception('Failed to generate Excel file bytes');

      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final String fileName = '${fileNamePrefix}_$timestamp.xlsx'.replaceAll(
        ' ',
        '_',
      );

      await _saveAndShareFile(
        bytes: fileBytes,
        fileName: fileName,
        shareTitle: shareTitle,
      );
    } catch (e) {
      debugPrint('Excel Export Error: $e');
      rethrow;
    }
  }

  /// Converts a list of inspections for a specific branch to a beautified Excel format and shares it.
  static Future<void> exportBranchInspections({
    required List<InspectionModel> inspections,
    required String fileNamePrefix,
    required String shareTitle,
    required String branchName,
    required String period,
  }) async {
    try {
      // 1. Create Excel workbook
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      // 2. Define Styles
      CellStyle headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#BFC9D2'),
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      CellStyle titleStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      CellStyle infoLabelStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      // 3. Add Header Section
      _addCell(sheet, 0, 0, 'BRANCH INSPECTIONS REPORT', style: titleStyle);

      _addCell(sheet, 0, 1, 'Branch Name:', style: infoLabelStyle);
      _addCell(sheet, 1, 1, branchName);

      _addCell(sheet, 0, 2, 'Total Inspections:', style: infoLabelStyle);
      _addCell(sheet, 1, 2, inspections.length);

      _addCell(sheet, 0, 3, 'Period:', style: infoLabelStyle);
      _addCell(sheet, 1, 3, period);

      _addCell(sheet, 0, 4, 'Generated At:', style: infoLabelStyle);
      _addCell(
        sheet,
        1,
        4,
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      );

      // Spacer row
      int currentRow = 6;

      // 4. Collect Category Columns
      Set<String> categoryNames = {};
      for (var inspection in inspections) {
        categoryNames.addAll(inspection.categories.keys);
      }
      List<String> sortedCategories = categoryNames.toList()..sort();

      // 5. Build Table Headers
      List<String> tableHeaders = [
        'Inspector Name',
        'Status',
        'Scheduled Time',
        'Completed Time',
        'Overall Score',
        'Representative Name',
        'Overall Notes',
        'Created At',
      ];

      for (var catName in sortedCategories) {
        tableHeaders.add('$catName Score');
        tableHeaders.add('$catName Notes');
      }
      tableHeaders.add('PDF Report URL');

      for (int i = 0; i < tableHeaders.length; i++) {
        _addCell(sheet, i, currentRow, tableHeaders[i], style: headerStyle);
      }
      currentRow++;

      // 6. Add Data Rows
      for (var inspection in inspections) {
        // Fix Score formatting to prevent Excel date conversion
        String formattedOverallScore = inspection.score.contains('/')
            ? ' ${inspection.score}'
            : inspection.score;

        List<dynamic> rowValues = [
          inspection.inspectorName,
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

        for (var catName in sortedCategories) {
          final categoryData = inspection.categories[catName];
          if (categoryData != null) {
            String formattedCatScore = categoryData.score.contains('/')
                ? ' ${categoryData.score}'
                : categoryData.score;
            rowValues.add(formattedCatScore);
            rowValues.add(categoryData.notes);
          } else {
            rowValues.add('N/A');
            rowValues.add('');
          }
        }
        rowValues.add(inspection.pdfReportUrl ?? '');

        for (int i = 0; i < rowValues.length; i++) {
          _addCell(sheet, i, currentRow, rowValues[i]);
        }
        currentRow++;
      }

      // 7. Save and Share
      final List<int>? fileBytes = excel.save();
      if (fileBytes == null)
        throw Exception('Failed to generate Excel file bytes');

      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final String fileName = '${fileNamePrefix}_$timestamp.xlsx'.replaceAll(
        ' ',
        '_',
      );

      await _saveAndShareFile(
        bytes: fileBytes,
        fileName: fileName,
        shareTitle: shareTitle,
      );
    } catch (e) {
      debugPrint('Excel Export Error: $e');
      rethrow;
    }
  }

  /// Export all branches' monthly inspection records with top/bottom 3 rankings
  static Future<void> exportMonthlyBranchRankings({
    required List<InspectionModel> inspections,
    required String monthName,
    required int year,
  }) async {
    try {
      if (inspections.isEmpty) {
        throw Exception('No inspections data to export');
      }

      // Group inspections by branch
      Map<String, List<InspectionModel>> branchInspections = {};
      for (var inspection in inspections) {
        if (!branchInspections.containsKey(inspection.branchId)) {
          branchInspections[inspection.branchId] = [];
        }
        branchInspections[inspection.branchId]!.add(inspection);
      }

      // Calculate rankings using last inspection per branch
      List<_BranchRanking> rankings = [];
      for (var entry in branchInspections.entries) {
        final lastInspection = entry.value.first; // Already sorted descending
        final percentageStr = calculatePerformancePercent(lastInspection.score);
        final percentage = double.tryParse(percentageStr) ?? 0.0;

        rankings.add(
          _BranchRanking(
            branchName: lastInspection.branchName,
            score: lastInspection.score,
            percentage: percentage,
          ),
        );
      }

      // Sort by percentage descending (best first)
      rankings.sort((a, b) => b.percentage.compareTo(a.percentage));

      // 1. Create Excel workbook
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      // 2. Define Styles
      CellStyle headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#BFC9D2'),
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      CellStyle titleStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      CellStyle infoLabelStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      CellStyle rankingHeaderStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#4CAF50'),
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      CellStyle warningHeaderStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#FF9800'),
        fontFamily: getFontFamily(FontFamily.Arial),
      );

      // 3. Add Header Section
      int currentRow = 0;
      // Merge title across 4 columns
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      );
      _addCell(
        sheet,
        0,
        currentRow,
        'MONTHLY BRANCH RANKINGS REPORT',
        style: titleStyle,
      );
      currentRow++;

      _addCell(sheet, 0, currentRow, 'Month:', style: infoLabelStyle);
      _addCell(sheet, 1, currentRow, '$monthName $year');
      currentRow++;

      _addCell(sheet, 0, currentRow, 'Total Branches:', style: infoLabelStyle);
      _addCell(sheet, 1, currentRow, rankings.length);
      currentRow++;

      _addCell(
        sheet,
        0,
        currentRow,
        'Total Inspections:',
        style: infoLabelStyle,
      );
      _addCell(sheet, 1, currentRow, inspections.length);
      currentRow++;

      _addCell(sheet, 0, currentRow, 'Generated At:', style: infoLabelStyle);
      _addCell(
        sheet,
        1,
        currentRow,
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      );
      currentRow += 2;

      // 4. Add Top 3 Branches Section
      // Merge cells for section header (A to D)
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      );
      _addCell(
        sheet,
        0,
        currentRow,
        '🏆 TOP 3 PERFORMING BRANCHES',
        style: rankingHeaderStyle,
      );
      currentRow++;

      _addCell(sheet, 0, currentRow, 'Rank', style: headerStyle);
      _addCell(sheet, 1, currentRow, 'Branch Name', style: headerStyle);
      _addCell(sheet, 2, currentRow, 'Score', style: headerStyle);
      _addCell(sheet, 3, currentRow, 'Percentage', style: headerStyle);
      currentRow++;

      final top3 = rankings.take(3).toList();
      for (int i = 0; i < top3.length; i++) {
        _addCell(sheet, 0, currentRow, i + 1);
        _addCell(sheet, 1, currentRow, top3[i].branchName);
        _addCell(sheet, 2, currentRow, top3[i].score);
        _addCell(
          sheet,
          3,
          currentRow,
          '${top3[i].percentage.toStringAsFixed(0)}%',
        );
        currentRow++;
      }
      currentRow++;

      // 5. Add Bottom 3 Branches Section
      // Merge cells for section header (A to D)
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      );
      _addCell(
        sheet,
        0,
        currentRow,
        '⚠️ BOTTOM 3 BRANCHES (NEED IMPROVEMENT)',
        style: warningHeaderStyle,
      );
      currentRow++;

      _addCell(sheet, 0, currentRow, 'Rank', style: headerStyle);
      _addCell(sheet, 1, currentRow, 'Branch Name', style: headerStyle);
      _addCell(sheet, 2, currentRow, 'Score', style: headerStyle);
      _addCell(sheet, 3, currentRow, 'Percentage', style: headerStyle);
      currentRow++;

      final bottom3 = rankings.reversed.take(3).toList().reversed.toList();
      int bottomStartRank = rankings.length - bottom3.length + 1;
      for (int i = 0; i < bottom3.length; i++) {
        _addCell(sheet, 0, currentRow, bottomStartRank + i);
        _addCell(sheet, 1, currentRow, bottom3[i].branchName);
        _addCell(sheet, 2, currentRow, bottom3[i].score);
        _addCell(
          sheet,
          3,
          currentRow,
          '${bottom3[i].percentage.toStringAsFixed(0)}%',
        );
        currentRow++;
      }
      currentRow += 2;

      // 6. Add All Inspections Details
      _addCell(
        sheet,
        0,
        currentRow,
        'ALL INSPECTION RECORDS',
        style: titleStyle,
      );
      currentRow++;

      // Collect all category columns
      Set<String> categoryNames = {};
      for (var inspection in inspections) {
        categoryNames.addAll(inspection.categories.keys);
      }
      List<String> sortedCategories = categoryNames.toList()..sort();

      // Build table headers
      List<String> tableHeaders = [
        'Branch Name',
        'Inspector Name',
        'Status',
        'Scheduled Time',
        'Completed Time',
        'Overall Score',
        'Representative Name',
        'Overall Notes',
        'Created At',
      ];

      for (var catName in sortedCategories) {
        tableHeaders.add('$catName Score');
        tableHeaders.add('$catName Notes');
      }
      tableHeaders.add('PDF Report URL');

      for (int i = 0; i < tableHeaders.length; i++) {
        _addCell(sheet, i, currentRow, tableHeaders[i], style: headerStyle);
      }
      currentRow++;

      // 7. Sort inspections by score (highest to lowest) and add data rows
      List<InspectionModel> sortedInspections = List.from(inspections);
      sortedInspections.sort((a, b) {
        // Extract numeric value from score string (e.g., "82.0/136" -> 82.0)
        double scoreA = double.tryParse(a.score.split('/').first) ?? 0;
        double scoreB = double.tryParse(b.score.split('/').first) ?? 0;
        return scoreB.compareTo(scoreA); // Descending order
      });

      for (var inspection in sortedInspections) {
        String formattedOverallScore = inspection.score.contains('/')
            ? ' ${inspection.score}'
            : inspection.score;

        List<dynamic> rowValues = [
          inspection.branchName,
          inspection.inspectorName,
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

        for (var catName in sortedCategories) {
          final categoryData = inspection.categories[catName];
          if (categoryData != null) {
            String formattedCatScore = categoryData.score.contains('/')
                ? ' ${categoryData.score}'
                : categoryData.score;
            rowValues.add(formattedCatScore);
            rowValues.add(categoryData.notes);
          } else {
            rowValues.add('N/A');
            rowValues.add('');
          }
        }
        rowValues.add(inspection.pdfReportUrl ?? '');

        for (int i = 0; i < rowValues.length; i++) {
          _addCell(sheet, i, currentRow, rowValues[i]);
        }
        currentRow++;
      }

      // 8. Save and Share
      final List<int>? fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file bytes');
      }

      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final String fileName =
          'Monthly_Rankings_${monthName}_${year}_$timestamp.xlsx'.replaceAll(
            ' ',
            '_',
          );

      await _saveAndShareFile(
        bytes: fileBytes,
        fileName: fileName,
        shareTitle: 'Monthly Branch Rankings - $monthName $year',
      );
    } catch (e) {
      debugPrint('Excel Export Error: $e');
      rethrow;
    }
  }

  static void _addCell(
    Sheet sheet,
    int col,
    int row,
    dynamic value, {
    CellStyle? style,
  }) {
    var cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value != null ? TextCellValue(value.toString()) : null;
    if (style != null) {
      cell.cellStyle = style;
    }
  }

  static Future<void> _saveAndShareFile({
    required List<int> bytes,
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
          await _shareOnly(bytes, fileName, shareTitle);
          return;
        }
      }
    }

    // 2. Save to public folder on Android
    if (Platform.isAndroid) {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final filePath = '${downloadDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          debugPrint('Saved to Downloads: $filePath');
        }
      } catch (e) {
        debugPrint('Direct save to Downloads failed: $e');
      }
    }

    // 3. Save to temp and share
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path)],
        text: shareTitle,
        subject: shareTitle,
      ),
    );
  }

  static Future<void> _shareOnly(
    List<int> bytes,
    String fileName,
    String shareTitle,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path)],
        text: shareTitle,
        subject: shareTitle,
      ),
    );
  }
}

// Helper class for branch ranking
class _BranchRanking {
  final String branchName;
  final String score;
  final double percentage;

  _BranchRanking({
    required this.branchName,
    required this.score,
    required this.percentage,
  });
}
