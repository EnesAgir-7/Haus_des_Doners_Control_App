import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../helpers/app_helpers.dart';

/// Complete PDF Generator for Inspection Reports
class InspectionPDFGenerator {
  final String inspectionId;
  final String branchName;
  final String branchAddress;
  final String inspectorName;
  final String? templateName;
  final List<CategoryScore> categories;
  final double totalScore;
  final double maxPossibleScore; // Add this to calculate percentage
  final String overallNotes;
  final Uint8List? inspectorSignature;
  final Uint8List? branchSignature;
  final Map<String, List<File>> categoryPhotos;

  InspectionPDFGenerator({
    required this.inspectionId,
    required this.branchName,
    required this.branchAddress,
    required this.inspectorName,
    this.templateName,
    required this.categories,
    required this.totalScore,
    required this.maxPossibleScore,
    this.overallNotes = '',
    this.inspectorSignature,
    this.branchSignature,
    this.categoryPhotos = const {},
  });

  /// Generate PDF document and return pw.Document
  /// Use this for preview or when you want to handle file saving yourself
  Future<pw.Document> generateDocument() async {
    return await _generateInspectionPDF();
  }

  /// Generate PDF and save as file directly
  /// Convenience method that handles everything
  Future<File> generateFile() async {
    try {
      final pw.Document pdfDocument = await _generateInspectionPDF();
      final directory = await getTemporaryDirectory();
      final fileName =
          'inspection_${inspectionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      final bytes = await pdfDocument.save();
      await file.writeAsBytes(bytes);
      print('PDF saved to: $filePath');
      return file;
    } catch (e) {
      print('Error generating PDF file: $e');
      rethrow;
    }
  }

  // ============================================
  // PRIVATE METHODS - PDF GENERATION
  // ============================================

  Future<pw.Document> _generateInspectionPDF() async {
    final pdf = pw.Document();
    final logoImage = await _loadLogo();
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildPDFHeader(logoImage, now, dateFormat),
          pw.SizedBox(height: 16),
          _buildInfoRow(),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1.5, color: PdfColors.red700),
          pw.SizedBox(height: 16),
          _buildOverallScoreCompact(),
          pw.SizedBox(height: 16),
          _buildCategoriesSection(),
          if (overallNotes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildOverallNotes(),
          ],
          pw.SizedBox(height: 20),
          _buildSignaturesSection(),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    if (_hasPhotos()) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                LocaleKeys.inspection_photos.tr(),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            ..._buildPhotosSection(),
          ],
        ),
      );
    }

    return pdf;
  }

  Future<pw.ImageProvider> _loadLogo() async {
    try {
      return await imageFromAssetBundle('assets/logo.png');
    } catch (e) {
      print('Logo not found: $e');
      rethrow;
    }
  }

  pw.Widget _buildPDFHeader(
    pw.ImageProvider logoImage,
    DateTime now,
    DateFormat dateFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.red700,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),

                child: pw.Image(logoImage, height: 20),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    LocaleKeys.inspection_report.tr(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'ID: #${now.millisecondsSinceEpoch.toString().substring(7)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              dateFormat.format(now),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow() {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red700,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Icon(
                        const pw.IconData(0xe0c8),
                        color: PdfColors.white,
                        size: 12,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      LocaleKeys.branch.tr(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  branchName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  branchAddress,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  LocaleKeys.inspector.tr(),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  inspectorName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  LocaleKeys.questionnaire.tr(),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  templateName ?? LocaleKeys.notAvailable.tr(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildOverallScoreCompact() {
    // Convert to score string format
    final scoreString =
        '${totalScore.toStringAsFixed(0)}/${maxPossibleScore.toStringAsFixed(0)}';

    // Use your global helper method
    final percentage = calculatePerformancePercent(scoreString);
    final percentValue = int.tryParse(percentage) ?? 0;
    final performanceLevel = _getPerformanceLevel(percentValue);

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            performanceLevel['color'] as PdfColor,
            (performanceLevel['color'] as PdfColor).shade(0.8),
          ],
        ),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                LocaleKeys.overall_score.tr(),
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    totalScore.toStringAsFixed(1),
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    ' / ${maxPossibleScore.toStringAsFixed(0)}',
                    style: const pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Container(
            width: 70,
            height: 70,
            decoration: const pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColors.white,
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '$percentage%',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: performanceLevel['color'] as PdfColor,
                    ),
                  ),
                  pw.Text(
                    performanceLevel['label'] as String,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: (performanceLevel['color'] as PdfColor).shade(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategoriesSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          LocaleKeys.categoryBreakdown.tr(),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red700,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell(LocaleKeys.category.tr(), isHeader: true),
                _buildTableCell(
                  LocaleKeys.score.tr(),
                  isHeader: true,
                  align: pw.Alignment.center,
                ),
                _buildTableCell(
                  LocaleKeys.status.tr(),
                  isHeader: true,
                  align: pw.Alignment.center,
                ),
              ],
            ),
            // Data Rows
            ...categories.map((category) {
              // Convert to score string format
              final scoreString = '${category.score}/${category.maxScore}';

              // Use your global helper method
              final percentage = calculatePerformancePercent(scoreString);
              final percentValue = int.tryParse(percentage) ?? 0;
              final performanceLevel = _getPerformanceLevel(percentValue);

              return pw.TableRow(
                children: [
                  _buildTableCell(
                    category.title,
                    fontSize: 10,
                    subtitle: category.notes.isNotEmpty ? category.notes : null,
                    photoCount: category.photoCount,
                  ),
                  _buildTableCell(
                    '${category.score}/${category.maxScore}',
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    align: pw.Alignment.center,
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    alignment: pw.Alignment.center,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: performanceLevel['color'] as PdfColor,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        '$percentage%',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    double fontSize = 9,
    pw.FontWeight? fontWeight,
    pw.Alignment? align,
    String? subtitle,
    int photoCount = 0,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: align ?? pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: align == pw.Alignment.center
            ? pw.CrossAxisAlignment.center
            : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: isHeader ? 10 : fontSize,
              fontWeight: isHeader
                  ? pw.FontWeight.bold
                  : (fontWeight ?? pw.FontWeight.normal),
              color: isHeader ? PdfColors.grey800 : PdfColors.black,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
              maxLines: 20,
            ),
          ],
          if (photoCount > 0) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              '$photoCount ${LocaleKeys.photos.tr()}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildOverallNotes() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          LocaleKeys.additionalInformation.tr(),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red700,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Text(overallNotes, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  pw.Widget _buildSignaturesSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignatureBox(
          LocaleKeys.inspectorSignature.tr(),
          inspectorSignature,
        ),
        pw.SizedBox(width: 16),
        _buildSignatureBox(
          LocaleKeys.branchRepresentative.tr(),
          branchSignature,
        ),
      ],
    );
  }

  pw.Widget _buildSignatureBox(String title, Uint8List? signature) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: signature != null
                ? pw.ClipRRect(
                    verticalRadius: 4,
                    horizontalRadius: 4,
                    child: pw.Image(
                      pw.MemoryImage(signature),
                      fit: pw.BoxFit.contain,
                    ),
                  )
                : pw.Center(
                    child: pw.Text(
                      LocaleKeys.not_signed.tr(),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Text(
        '${LocaleKeys.page.tr()} ${context.pageNumber} ${LocaleKeys.of.tr()} ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    );
  }

  List<pw.Widget> _buildPhotosSection() {
    final List<pw.Widget> widgets = [];

    for (final category in categories) {
      final photos = categoryPhotos[category.categoryId];
      if (photos == null || photos.isEmpty) continue;

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                '${category.title} (${category.score}/${category.maxScore})',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.GridView(
              childAspectRatio: 1.0,
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: photos.map((photo) {
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(
                      pw.MemoryImage(photo.readAsBytesSync()),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
      );
    }

    return widgets;
  }

  bool _hasPhotos() {
    return categoryPhotos.values.any((photos) => photos.isNotEmpty);
  }

  // Determine performance based on reversed percentage
  Map<String, dynamic> _getPerformanceLevel(int percentage) {
    if (percentage >= 90) {
      return {
        'label': LocaleKeys.excellent.tr(),
        'emoji': '😃',
        'color': PdfColors.green700,
      };
    } else if (percentage >= 75) {
      return {
        'label': LocaleKeys.good.tr(),
        'emoji': '🙂',
        'color': PdfColors.lightGreen700,
      };
    } else if (percentage >= 60) {
      return {
        'label': LocaleKeys.fair.tr(),
        'emoji': '😐',
        'color': PdfColors.orange700,
      };
    } else if (percentage >= 40) {
      return {
        'label': LocaleKeys.belowAverage.tr(),
        'emoji': '😕',
        'color': PdfColors.deepOrange700,
      };
    } else if (percentage >= 20) {
      return {
        'label': LocaleKeys.poor.tr(),
        'emoji': '😞',
        'color': PdfColors.red700,
      };
    } else {
      return {
        'label': LocaleKeys.veryPoor.tr(),
        'emoji': '😢',
        'color': PdfColors.red900,
      };
    }
  }
}

class CategoryScore {
  final String categoryId;
  final String title;
  final int score;
  final int maxScore; // Add this field
  final String notes;
  final int photoCount;

  CategoryScore({
    required this.categoryId,
    required this.title,
    required this.score,
    required this.maxScore, // Make it required
    this.notes = '',
    this.photoCount = 0,
  });
}

// /// Complete PDF Generator for Inspection Reports
// class InspectionPDFGenerator {
//   final String inspectionId;
//   final String branchName;
//   final String branchAddress;
//   final String inspectorName;
//   final String? templateName;
//   final List<CategoryScore> categories;
//   final double totalScore;
//   final String overallNotes;
//   final Uint8List? inspectorSignature;
//   final Uint8List? branchSignature;
//   final Map<String, List<File>> categoryPhotos;

//   InspectionPDFGenerator({
//     required this.inspectionId,
//     required this.branchName,
//     required this.branchAddress,
//     required this.inspectorName,
//     this.templateName,
//     required this.categories,
//     required this.totalScore,
//     this.overallNotes = '',
//     this.inspectorSignature,
//     this.branchSignature,
//     this.categoryPhotos = const {},
//   });

//   /// Generate PDF document and return pw.Document
//   /// Use this for preview or when you want to handle file saving yourself
//   Future<pw.Document> generateDocument() async {
//     return await _generateInspectionPDF();
//   }

//   /// Generate PDF and save as file directly
//   /// Convenience method that handles everything
//   Future<File> generateFile() async {
//     try {
//       final pw.Document pdfDocument = await _generateInspectionPDF();
//       final directory = await getTemporaryDirectory();
//       final fileName =
//           'inspection_${inspectionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final filePath = '${directory.path}/$fileName';
//       final file = File(filePath);
//       final bytes = await pdfDocument.save();
//       await file.writeAsBytes(bytes);
//       print('PDF saved to: $filePath');
//       return file;
//     } catch (e) {
//       print('Error generating PDF file: $e');
//       rethrow;
//     }
//   }

//   // ============================================
//   // PRIVATE METHODS - PDF GENERATION
//   // ============================================

//   Future<pw.Document> _generateInspectionPDF() async {
//     final pdf = pw.Document();
//     final logoImage = await _loadLogo();
//     final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');
//     final now = DateTime.now();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         build: (context) => [
//           _buildPDFHeader(logoImage, now, dateFormat),
//           pw.SizedBox(height: 20),
//           _buildBranchInfo(),
//           pw.SizedBox(height: 20),
//           _buildInspectorInfo(dateFormat, now),
//           pw.SizedBox(height: 20),
//           pw.Divider(thickness: 2, color: PdfColors.red700),
//           pw.SizedBox(height: 20),
//           _buildCategoriesSection(),
//           pw.SizedBox(height: 20),
//           _buildOverallScore(),
//           pw.SizedBox(height: 20),
//           if (overallNotes.isNotEmpty) _buildOverallNotes(),
//           pw.SizedBox(height: 30),
//           _buildSignaturesSection(),
//         ],
//         footer: (context) => _buildFooter(context),
//       ),
//     );

//     if (_hasPhotos()) {
//       pdf.addPage(
//         pw.MultiPage(
//           pageFormat: PdfPageFormat.a4,
//           margin: const pw.EdgeInsets.all(32),
//           build: (context) => [
//             pw.Header(
//               level: 0,
//               child: pw.Text(
//                 'Inspection Photos',
//                 style: pw.TextStyle(
//                   fontSize: 24,
//                   fontWeight: pw.FontWeight.bold,
//                   color: PdfColors.red700,
//                 ),
//               ),
//             ),
//             pw.SizedBox(height: 20),
//             ..._buildPhotosSection(),
//           ],
//         ),
//       );
//     }

//     return pdf;
//   }

//   Future<pw.ImageProvider> _loadLogo() async {
//     try {
//       return await imageFromAssetBundle('assets/logo.png');
//     } catch (e) {
//       print('Logo not found: $e');
//       rethrow;
//     }
//   }

//   pw.Widget _buildPDFHeader(
//     pw.ImageProvider logoImage,
//     DateTime now,
//     DateFormat dateFormat,
//   ) {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Image(logoImage, width: 80, height: 80),
//             pw.SizedBox(height: 8),
//             pw.Text(
//               'INSPECTION REPORT',
//               style: pw.TextStyle(
//                 fontSize: 24,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.red700,
//               ),
//             ),
//           ],
//         ),
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.end,
//           children: [
//             pw.Text(
//               'Report ID',
//               style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
//             ),
//             pw.Text(
//               '#${now.millisecondsSinceEpoch.toString().substring(7)}',
//               style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
//             ),
//             pw.SizedBox(height: 8),
//             pw.Text(
//               dateFormat.format(now),
//               style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   pw.Widget _buildBranchInfo() {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(16),
//       decoration: pw.BoxDecoration(
//         color: PdfColors.grey200,
//         borderRadius: pw.BorderRadius.circular(8),
//         border: pw.Border.all(color: PdfColors.red700, width: 2),
//       ),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Row(
//             children: [
//               pw.Container(
//                 padding: const pw.EdgeInsets.all(8),
//                 decoration: pw.BoxDecoration(
//                   color: PdfColors.red700,
//                   borderRadius: pw.BorderRadius.circular(4),
//                 ),
//                 child: pw.Icon(
//                   const pw.IconData(0xe0c8),
//                   color: PdfColors.white,
//                   size: 20,
//                 ),
//               ),
//               pw.SizedBox(width: 12),
//               pw.Text(
//                 'Branch Information',
//                 style: pw.TextStyle(
//                   fontSize: 14,
//                   fontWeight: pw.FontWeight.bold,
//                   color: PdfColors.red700,
//                 ),
//               ),
//             ],
//           ),
//           pw.SizedBox(height: 12),
//           pw.Text(
//             branchName,
//             style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
//           ),
//           pw.SizedBox(height: 4),
//           pw.Text(
//             branchAddress,
//             style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
//           ),
//         ],
//       ),
//     );
//   }

//   pw.Widget _buildInspectorInfo(DateFormat dateFormat, DateTime now) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(16),
//       decoration: pw.BoxDecoration(
//         color: PdfColors.grey100,
//         borderRadius: pw.BorderRadius.circular(8),
//       ),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 'Inspector',
//                 style: const pw.TextStyle(
//                   fontSize: 10,
//                   color: PdfColors.grey700,
//                 ),
//               ),
//               pw.SizedBox(height: 4),
//               pw.Text(
//                 inspectorName,
//                 style: pw.TextStyle(
//                   fontSize: 14,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.end,
//             children: [
//               pw.Text(
//                 'Template',
//                 style: const pw.TextStyle(
//                   fontSize: 10,
//                   color: PdfColors.grey700,
//                 ),
//               ),
//               pw.SizedBox(height: 4),
//               pw.Text(
//                 templateName ?? 'N/A',
//                 style: pw.TextStyle(
//                   fontSize: 14,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   pw.Widget _buildCategoriesSection() {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           'Inspection Details',
//           style: pw.TextStyle(
//             fontSize: 18,
//             fontWeight: pw.FontWeight.bold,
//             color: PdfColors.red700,
//           ),
//         ),
//         pw.SizedBox(height: 16),
//         ...categories.map((category) {
//           return pw.Container(
//             margin: const pw.EdgeInsets.only(bottom: 12),
//             padding: const pw.EdgeInsets.all(12),
//             decoration: pw.BoxDecoration(
//               border: pw.Border.all(color: PdfColors.grey400),
//               borderRadius: pw.BorderRadius.circular(8),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                   children: [
//                     pw.Expanded(
//                       child: pw.Text(
//                         category.title,
//                         style: pw.TextStyle(
//                           fontSize: 14,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 6,
//                       ),
//                       decoration: pw.BoxDecoration(
//                         color: _getScoreColor(category.score),
//                         borderRadius: pw.BorderRadius.circular(4),
//                       ),
//                       child: pw.Text(
//                         '${category.score}/4',
//                         style: pw.TextStyle(
//                           fontSize: 12,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (category.notes.isNotEmpty) ...[
//                   pw.SizedBox(height: 8),
//                   pw.Container(
//                     padding: const pw.EdgeInsets.all(8),
//                     decoration: pw.BoxDecoration(
//                       color: PdfColors.grey200,
//                       borderRadius: pw.BorderRadius.circular(4),
//                     ),
//                     child: pw.Text(
//                       category.notes,
//                       style: const pw.TextStyle(
//                         fontSize: 10,
//                         color: PdfColors.grey800,
//                       ),
//                     ),
//                   ),
//                 ],
//                 if (category.photoCount > 0) ...[
//                   pw.SizedBox(height: 8),
//                   pw.Text(
//                     '${category.photoCount} photo(s) attached',
//                     style: const pw.TextStyle(
//                       fontSize: 10,
//                       color: PdfColors.grey700,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         }).toList(),
//       ],
//     );
//   }

//   pw.Widget _buildOverallScore() {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(20),
//       decoration: pw.BoxDecoration(
//         color: PdfColors.red50,
//         borderRadius: pw.BorderRadius.circular(8),
//         border: pw.Border.all(color: PdfColors.red700, width: 2),
//       ),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 'Total Score',
//                 style: pw.TextStyle(
//                   fontSize: 14,
//                   fontWeight: pw.FontWeight.bold,
//                   color: PdfColors.red700,
//                 ),
//               ),
//               pw.SizedBox(height: 4),
//               pw.Text(
//                 totalScore.toStringAsFixed(1),
//                 style: pw.TextStyle(
//                   fontSize: 36,
//                   fontWeight: pw.FontWeight.bold,
//                   color: PdfColors.red700,
//                 ),
//               ),
//             ],
//           ),
//           pw.Container(
//             width: 80,
//             height: 80,
//             decoration: pw.BoxDecoration(
//               shape: pw.BoxShape.circle,
//               color: PdfColors.red700,
//             ),
//             child: pw.Center(
//               child: pw.Icon(
//                 const pw.IconData(0xe838),
//                 color: PdfColors.white,
//                 size: 40,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   pw.Widget _buildOverallNotes() {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           'Overall Notes',
//           style: pw.TextStyle(
//             fontSize: 14,
//             fontWeight: pw.FontWeight.bold,
//             color: PdfColors.red700,
//           ),
//         ),
//         pw.SizedBox(height: 8),
//         pw.Container(
//           width: double.infinity,
//           padding: const pw.EdgeInsets.all(12),
//           decoration: pw.BoxDecoration(
//             color: PdfColors.grey100,
//             borderRadius: pw.BorderRadius.circular(8),
//           ),
//           child: pw.Text(overallNotes, style: const pw.TextStyle(fontSize: 12)),
//         ),
//       ],
//     );
//   }

//   pw.Widget _buildSignaturesSection() {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [
//         _buildSignatureBox('Inspector Signature', inspectorSignature),
//         pw.SizedBox(width: 20),
//         _buildSignatureBox('Branch Representative', branchSignature),
//       ],
//     );
//   }

//   pw.Widget _buildSignatureBox(String title, Uint8List? signature) {
//     return pw.Expanded(
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             title,
//             style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
//           ),
//           pw.SizedBox(height: 8),
//           pw.Container(
//             height: 80,
//             child: signature != null
//                 ? pw.ClipRRect(
//                     verticalRadius: 8,
//                     horizontalRadius: 8,
//                     child: pw.Image(
//                       pw.MemoryImage(signature),
//                       fit: pw.BoxFit.contain,
//                     ),
//                   )
//                 : pw.Center(
//                     child: pw.Text(
//                       'No Signature',
//                       style: const pw.TextStyle(
//                         fontSize: 10,
//                         color: PdfColors.grey600,
//                       ),
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   pw.Widget _buildFooter(pw.Context context) {
//     return pw.Container(
//       alignment: pw.Alignment.centerRight,
//       margin: const pw.EdgeInsets.only(top: 16),
//       child: pw.Text(
//         'Page ${context.pageNumber} of ${context.pagesCount}',
//         style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
//       ),
//     );
//   }

//   List<pw.Widget> _buildPhotosSection() {
//     final List<pw.Widget> widgets = [];

//     for (final category in categories) {
//       final photos = categoryPhotos[category.categoryId];
//       if (photos == null || photos.isEmpty) continue;

//       widgets.add(
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text(
//               category.title,
//               style: pw.TextStyle(
//                 fontSize: 16,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.red700,
//               ),
//             ),
//             pw.SizedBox(height: 12),
//             pw.GridView(
//               childAspectRatio: 1.0,
//               crossAxisCount: 3,
//               mainAxisSpacing: 12,
//               crossAxisSpacing: 12,
//               children: photos.map((photo) {
//                 return pw.Container(
//                   decoration: pw.BoxDecoration(
//                     border: pw.Border.all(color: PdfColors.grey400),
//                     borderRadius: pw.BorderRadius.circular(8),
//                   ),
//                   child: pw.ClipRRect(
//                     horizontalRadius: 8,
//                     verticalRadius: 8,
//                     child: pw.Image(
//                       pw.MemoryImage(photo.readAsBytesSync()),
//                       fit: pw.BoxFit.cover,
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//             pw.SizedBox(height: 20),
//           ],
//         ),
//       );
//     }

//     return widgets;
//   }

//   bool _hasPhotos() {
//     return categoryPhotos.values.any((photos) => photos.isNotEmpty);
//   }

//   PdfColor _getScoreColor(int score) {
//     switch (score) {
//       case 1:
//         return PdfColors.green700;
//       case 2:
//         return PdfColors.blue700;
//       case 3:
//         return PdfColors.orange700;
//       case 4:
//         return PdfColors.red700;
//       default:
//         return PdfColors.grey600;
//     }
//   }
// }

// class CategoryScore {
//   final String categoryId;
//   final String title;
//   final int score;
//   final String notes;
//   final int photoCount;

//   CategoryScore({
//     required this.categoryId,
//     required this.title,
//     required this.score,
//     this.notes = '',
//     this.photoCount = 0,
//   });
// }
