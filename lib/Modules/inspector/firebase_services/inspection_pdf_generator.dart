import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../helpers/app_helpers.dart';

class InspectionPDFGenerator {
  final String inspectionId;
  final String branchName;
  final String branchAddress;
  final String inspectorName;
  final String? templateName;
  final List<CategoryScore> categories;
  final double totalScore;
  final double maxPossibleScore;
  final String overallNotes;
  final Uint8List? inspectorSignature;
  final Uint8List? branchSignature;
  final Map<String, List<File>> categoryPhotos;
  final Map<String, bool>?
  enabledCategories; // Track which questions are enabled

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
    this.enabledCategories, // Optional, defaults to all enabled
  });

  static pw.Font? _cachedFont;

  Future<void> _loadFonts() async {
    if (_cachedFont != null) return;
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto.ttf');
      _cachedFont = pw.Font.ttf(fontData);
    } catch (e) {
      print('Custom font not found: $e');
      rethrow;
    }
  }

  Future<pw.Document> generateDocument() async {
    await _loadFonts();
    return await _generateInspectionPDF();
  }

  Future<File> generateFile() async {
    try {
      await _loadFonts();
      final pw.Document pdfDocument = await _generateInspectionPDF();
      final directory = await getTemporaryDirectory();
      final fileName =
          'inspection_${inspectionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      final bytes = await pdfDocument.save();
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error generating PDF file: $e');
      rethrow;
    }
  }

  Future<pw.Document> _generateInspectionPDF() async {
    final pdf = pw.Document();
    final logoImage = await _loadLogo();
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final now = DateTime.now();
    final theme = pw.ThemeData.withFont(base: _cachedFont!, bold: _cachedFont!);

    // Main Report Page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: theme,
        build: (context) => [
          _buildPDFHeader(logoImage, now, dateFormat),
          pw.SizedBox(height: 16),
          _buildInfoRow(),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1.5, color: PdfColors.red700),
          pw.SizedBox(height: 16),
          _buildOverallScoreCompact(),
          pw.SizedBox(height: 16),
          _buildCategoriesSection(), // Refactored to avoid Table
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

    // Photos Page
    if (_hasPhotos()) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: theme,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                "Inspektionsfotos",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            ..._buildPhotosSection(), // Refactored to avoid GridView
          ],
          footer: (context) => _buildFooter(context),
        ),
      );
    }

    return pdf;
  }

  // --- REFACTORED CATEGORY SECTION (No Table) ---
  pw.Widget _buildCategoriesSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Kategorieaufschlüsselung",
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red700,
          ),
        ),
        pw.SizedBox(height: 10),
        // Header Row
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.all(6),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  "Kategorie",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  "Bewertung",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  "Status",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // Data Rows
        ...categories.map((category) {
          // Check if category is skipped
          final isSkipped = category.isSkipped ?? false;
          final scoreString = '${category.score}/${category.maxScore}';
          final percentage = calculatePerformancePercent(scoreString);
          final percentValue = int.tryParse(percentage) ?? 0;
          final performanceLevel = _getPerformanceLevel(percentValue);

          return pw.Container(
            decoration: pw.BoxDecoration(
              color: isSkipped ? PdfColors.grey50 : null,
              border: const pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Title with strikethrough if skipped
                      pw.Text(
                        category.title,
                        style: pw.TextStyle(
                          fontSize: 10,
                          decoration: isSkipped
                              ? pw.TextDecoration.lineThrough
                              : null,
                          color: isSkipped
                              ? PdfColors.grey600
                              : PdfColors.black,
                        ),
                      ),
                      // Show "Not Applicable" note if skipped
                      if (isSkipped)
                        pw.Text(
                          "Not Applicable",
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        )
                      else if (category.notes.isNotEmpty)
                        pw.Text(
                          category.notes,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    isSkipped
                        ? 'N/A'
                        : '${category.score}/${category.maxScore}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: isSkipped ? PdfColors.grey600 : PdfColors.black,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: isSkipped
                            ? PdfColors.grey400
                            : (performanceLevel['color'] as PdfColor),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        isSkipped ? 'Skipped' : '$percentage%',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // --- REFACTORED PHOTOS SECTION (No GridView) ---
  List<pw.Widget> _buildPhotosSection() {
    final List<pw.Widget> widgets = [];

    for (final category in categories) {
      // Skip disabled/skipped categories in photos section
      final isSkipped = category.isSkipped ?? false;
      if (isSkipped) continue;

      final photos = categoryPhotos[category.categoryId];
      if (photos == null || photos.isEmpty) continue;

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            category.title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red700,
            ),
          ),
        ),
      );

      widgets.add(
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: photos.map((photo) {
            return pw.Container(
              width:
                  160, // Fixed width helps the wrap engine calculate page breaks
              height: 160,
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
      );
      widgets.add(pw.SizedBox(height: 20));
    }
    return widgets;
  }

  // Helper methods (kept mostly same as your original, but clean)
  Future<pw.ImageProvider> _loadLogo() async {
    try {
      return await imageFromAssetBundle('assets/logo.png');
    } catch (e) {
      return pw.MemoryImage(Uint8List(0)); // Fallback
    }
  }

  pw.Widget _buildPDFHeader(
    pw.ImageProvider logo,
    DateTime now,
    DateFormat df,
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
              pw.Image(logo, height: 20),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "INSPEKTIONSBERICHT",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
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
              df.format(now),
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
          child: _infoBox("Filiale", branchName, subtitle: branchAddress),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _infoBox(
            "Inspektor",
            inspectorName,
            subtitle: templateName ?? "N/V",
          ),
        ),
      ],
    );
  }

  pw.Widget _infoBox(String title, String main, {String? subtitle}) {
    return pw.Container(
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
            title,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Text(
            main,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          if (subtitle != null)
            pw.Text(
              subtitle,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              maxLines: 1,
            ),
        ],
      ),
    );
  }

  pw.Widget _buildOverallScoreCompact() {
    final scoreString =
        '${totalScore.toStringAsFixed(0)}/${maxPossibleScore.toStringAsFixed(0)}';
    final percentage = calculatePerformancePercent(scoreString);
    final percentValue = int.tryParse(percentage) ?? 0;
    final performanceLevel = _getPerformanceLevel(percentValue);

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: performanceLevel['color'] as PdfColor,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Gesamtpunktzahl",
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
              ),
              pw.Row(
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
            width: 60,
            height: 60,
            decoration: const pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColors.white,
            ),
            child: pw.Center(
              child: pw.Text(
                '$percentage%',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: performanceLevel['color'] as PdfColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildOverallNotes() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Zusätzliche Informationen",
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
      children: [
        _buildSigBox("Inspektor", inspectorSignature),
        pw.SizedBox(width: 16),
        _buildSigBox("Filialvertreter", branchSignature),
      ],
    );
  }

  pw.Widget _buildSigBox(String label, Uint8List? data) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: data != null
                ? pw.Image(pw.MemoryImage(data), fit: pw.BoxFit.contain)
                : pw.Center(
                    child: pw.Text(
                      "N/V",
                      style: const pw.TextStyle(fontSize: 8),
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
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Text(
        'Seite ${context.pageNumber} von ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  bool _hasPhotos() => categoryPhotos.values.any((p) => p.isNotEmpty);

  Map<String, dynamic> _getPerformanceLevel(int percentage) {
    if (percentage >= 90)
      return {'label': "Ausgezeichnet", 'color': PdfColors.green700};
    if (percentage >= 75)
      return {'label': "Gut", 'color': PdfColors.lightGreen700};
    if (percentage >= 60)
      return {'label': "Befriedigend", 'color': PdfColors.orange700};
    if (percentage >= 40)
      return {'label': "Mittel", 'color': PdfColors.deepOrange700};
    return {'label': "Schlecht", 'color': PdfColors.red700};
  }
}

class CategoryScore {
  final String categoryId;
  final String title;
  final int score;
  final int maxScore;
  final String notes;
  final int photoCount;
  final bool? isSkipped; // Indicates if question was disabled/not applicable

  CategoryScore({
    required this.categoryId,
    required this.title,
    required this.score,
    required this.maxScore,
    this.notes = '',
    this.photoCount = 0,
    this.isSkipped, // Optional, defaults to false
  });
}

// /// Complete PDF Generator for Inspection Reports with Turkish/German character support
// class InspectionPDFGenerator {
//   final String inspectionId;
//   final String branchName;
//   final String branchAddress;
//   final String inspectorName;
//   final String? templateName;
//   final List<CategoryScore> categories;
//   final double totalScore;
//   final double maxPossibleScore;
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
//     required this.maxPossibleScore,
//     this.overallNotes = '',
//     this.inspectorSignature,
//     this.branchSignature,
//     this.categoryPhotos = const {},
//   });

//   // Cache the font to avoid loading it multiple times
//   static pw.Font? _cachedFont;

//   /// Load custom font that supports Turkish/German characters
//   Future<void> _loadFonts() async {
//     if (_cachedFont != null) return;

//     try {
//       // Load Roboto font (supports Turkish/German characters)
//       final fontData = await rootBundle.load('assets/fonts/Roboto.ttf');
//       _cachedFont = pw.Font.ttf(fontData);
//     } catch (e) {
//       print('Custom font not found: $e');
//       rethrow;
//     }
//   }

//   /// Generate PDF document and return pw.Document
//   Future<pw.Document> generateDocument() async {
//     await _loadFonts(); // Load fonts first
//     return await _generateInspectionPDF();
//   }

//   /// Generate PDF and save as file directly
//   Future<File> generateFile() async {
//     try {
//       await _loadFonts(); // Load fonts first
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

//   Future<pw.Document> _generateInspectionPDF() async {
//     final pdf = pw.Document();
//     final logoImage = await _loadLogo();
//     final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
//     final now = DateTime.now();

//     // Create theme with custom font
//     final theme = pw.ThemeData.withFont(base: _cachedFont!, bold: _cachedFont!);

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(24),
//         theme: theme, // Apply custom font theme
//         build: (context) => [
//           _buildPDFHeader(logoImage, now, dateFormat),
//           pw.SizedBox(height: 16),
//           _buildInfoRow(),
//           pw.SizedBox(height: 16),
//           pw.Divider(thickness: 1.5, color: PdfColors.red700),
//           pw.SizedBox(height: 16),
//           _buildOverallScoreCompact(),
//           pw.SizedBox(height: 16),
//           _buildCategoriesSection(),
//           if (overallNotes.isNotEmpty) ...[
//             pw.SizedBox(height: 16),
//             _buildOverallNotes(),
//           ],
//           pw.SizedBox(height: 20),
//           _buildSignaturesSection(),
//         ],
//         footer: (context) => _buildFooter(context),
//       ),
//     );

//     if (_hasPhotos()) {
//       pdf.addPage(
//         pw.MultiPage(
//           pageFormat: PdfPageFormat.a4,
//           margin: const pw.EdgeInsets.all(24),
//           theme: theme, // Apply custom font theme
//           build: (context) => [
//             pw.Header(
//               level: 0,
//               child: pw.Text(
//                 "Inspektionsfotos",
//                 style: pw.TextStyle(
//                   fontSize: 20,
//                   fontWeight: pw.FontWeight.bold,
//                   color: PdfColors.red700,
//                 ),
//               ),
//             ),
//             pw.SizedBox(height: 16),
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
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(12),
//       decoration: pw.BoxDecoration(
//         color: PdfColors.red700,
//         borderRadius: pw.BorderRadius.circular(6),
//       ),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Row(
//             children: [
//               pw.Container(
//                 padding: const pw.EdgeInsets.all(6),
//                 child: pw.Image(logoImage, height: 20),
//               ),
//               pw.SizedBox(width: 12),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     "INSPEKTIONSBERICHT",
//                     style: pw.TextStyle(
//                       fontSize: 14,
//                       fontWeight: pw.FontWeight.bold,
//                       color: PdfColors.white,
//                     ),
//                   ),
//                   pw.SizedBox(height: 2),
//                   pw.Text(
//                     'ID: #${now.millisecondsSinceEpoch.toString().substring(7)}',
//                     style: const pw.TextStyle(
//                       fontSize: 10,
//                       color: PdfColors.white,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           pw.Container(
//             padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             decoration: pw.BoxDecoration(
//               color: PdfColors.white,
//               borderRadius: pw.BorderRadius.circular(4),
//             ),
//             child: pw.Text(
//               dateFormat.format(now),
//               style: pw.TextStyle(
//                 fontSize: 11,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.red700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   pw.Widget _buildInfoRow() {
//     return pw.Row(
//       children: [
//         pw.Expanded(
//           flex: 2,
//           child: pw.Container(
//             padding: const pw.EdgeInsets.all(10),
//             decoration: pw.BoxDecoration(
//               color: PdfColors.grey200,
//               borderRadius: pw.BorderRadius.circular(6),
//               border: pw.Border.all(color: PdfColors.grey400),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Row(
//                   children: [
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       decoration: pw.BoxDecoration(
//                         color: PdfColors.red700,
//                         borderRadius: pw.BorderRadius.circular(3),
//                       ),
//                       child: pw.SvgImage(
//                         svg: '''
//     <svg width="12" height="12" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
//       <path d="M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5v8H21V2c-2.76 0-5 2.24-5 4z" fill="white"/>
//     </svg>
//   ''',
//                         width: 12,
//                         height: 12,
//                       ),
//                     ),
//                     pw.SizedBox(width: 6),
//                     pw.Text(
//                       "Filiale",
//                       style: pw.TextStyle(
//                         fontSize: 10,
//                         fontWeight: pw.FontWeight.bold,
//                         color: PdfColors.grey700,
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 6),
//                 pw.Text(
//                   branchName,
//                   style: pw.TextStyle(
//                     fontSize: 12,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.SizedBox(height: 2),
//                 pw.Text(
//                   branchAddress,
//                   style: const pw.TextStyle(
//                     fontSize: 9,
//                     color: PdfColors.grey700,
//                   ),
//                   maxLines: 2,
//                   overflow: pw.TextOverflow.clip,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         pw.SizedBox(width: 12),
//         pw.Expanded(
//           child: pw.Container(
//             padding: const pw.EdgeInsets.all(10),
//             decoration: pw.BoxDecoration(
//               color: PdfColors.grey100,
//               borderRadius: pw.BorderRadius.circular(6),
//               border: pw.Border.all(color: PdfColors.grey300),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   "Inspektor",
//                   style: const pw.TextStyle(
//                     fontSize: 9,
//                     color: PdfColors.grey700,
//                   ),
//                 ),
//                 pw.SizedBox(height: 4),
//                 pw.Text(
//                   inspectorName,
//                   style: pw.TextStyle(
//                     fontSize: 11,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.SizedBox(height: 8),
//                 pw.Text(
//                   "Fragebogen",
//                   style: const pw.TextStyle(
//                     fontSize: 9,
//                     color: PdfColors.grey700,
//                   ),
//                 ),
//                 pw.SizedBox(height: 4),
//                 pw.Text(
//                   templateName ?? "N/V",
//                   style: pw.TextStyle(
//                     fontSize: 11,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   pw.Widget _buildOverallScoreCompact() {
//     final scoreString =
//         '${totalScore.toStringAsFixed(0)}/${maxPossibleScore.toStringAsFixed(0)}';
//     final percentage = calculatePerformancePercent(scoreString);
//     final percentValue = int.tryParse(percentage) ?? 0;
//     final performanceLevel = _getPerformanceLevel(percentValue);

//     return pw.Container(
//       padding: const pw.EdgeInsets.all(14),
//       decoration: pw.BoxDecoration(
//         gradient: pw.LinearGradient(
//           colors: [
//             performanceLevel['color'] as PdfColor,
//             (performanceLevel['color'] as PdfColor).shade(0.8),
//           ],
//         ),
//         borderRadius: pw.BorderRadius.circular(6),
//       ),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 "Gesamtpunktzahl",
//                 style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
//               ),
//               pw.SizedBox(height: 4),
//               pw.Row(
//                 crossAxisAlignment: pw.CrossAxisAlignment.center,
//                 children: [
//                   pw.Text(
//                     totalScore.toStringAsFixed(1),
//                     style: pw.TextStyle(
//                       fontSize: 32,
//                       fontWeight: pw.FontWeight.bold,
//                       color: PdfColors.white,
//                     ),
//                   ),
//                   pw.Text(
//                     ' / ${maxPossibleScore.toStringAsFixed(0)}',
//                     style: const pw.TextStyle(
//                       fontSize: 16,
//                       color: PdfColors.white,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           pw.Container(
//             width: 70,
//             height: 70,
//             decoration: const pw.BoxDecoration(
//               shape: pw.BoxShape.circle,
//               color: PdfColors.white,
//             ),
//             child: pw.Center(
//               child: pw.Column(
//                 mainAxisAlignment: pw.MainAxisAlignment.center,
//                 children: [
//                   pw.Text(
//                     '$percentage%',
//                     style: pw.TextStyle(
//                       fontSize: 20,
//                       fontWeight: pw.FontWeight.bold,
//                       color: performanceLevel['color'] as PdfColor,
//                     ),
//                   ),
//                   pw.Text(
//                     performanceLevel['label'] as String,
//                     style: pw.TextStyle(
//                       fontSize: 8,
//                       color: (performanceLevel['color'] as PdfColor).shade(0.7),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
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
//           "Kategorieaufschlüsselung",
//           style: pw.TextStyle(
//             fontSize: 14,
//             fontWeight: pw.FontWeight.bold,
//             color: PdfColors.red700,
//           ),
//         ),
//         pw.SizedBox(height: 10),
//         pw.Table(
//           border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
//           columnWidths: {
//             0: const pw.FlexColumnWidth(3),
//             1: const pw.FlexColumnWidth(1),
//             2: const pw.FlexColumnWidth(2),
//           },
//           children: [
//             pw.TableRow(
//               decoration: const pw.BoxDecoration(color: PdfColors.grey200),
//               children: [
//                 _buildTableCell("Kategorie", isHeader: true),
//                 _buildTableCell(
//                   "Bewertung",
//                   isHeader: true,
//                   align: pw.Alignment.center,
//                 ),
//                 _buildTableCell(
//                   "Status",
//                   isHeader: true,
//                   align: pw.Alignment.center,
//                 ),
//               ],
//             ),
//             ...categories.map((category) {
//               final scoreString = '${category.score}/${category.maxScore}';
//               final percentage = calculatePerformancePercent(scoreString);
//               final percentValue = int.tryParse(percentage) ?? 0;
//               final performanceLevel = _getPerformanceLevel(percentValue);

//               return pw.TableRow(
//                 children: [
//                   _buildTableCell(
//                     category.title,
//                     fontSize: 10,
//                     subtitle: category.notes.isNotEmpty ? category.notes : null,
//                     photoCount: category.photoCount,
//                   ),
//                   _buildTableCell(
//                     '${category.score}/${category.maxScore}',
//                     fontSize: 11,
//                     fontWeight: pw.FontWeight.bold,
//                     align: pw.Alignment.center,
//                   ),
//                   pw.Container(
//                     padding: const pw.EdgeInsets.all(6),
//                     alignment: pw.Alignment.center,
//                     child: pw.Container(
//                       padding: const pw.EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: pw.BoxDecoration(
//                         color: performanceLevel['color'] as PdfColor,
//                         borderRadius: pw.BorderRadius.circular(3),
//                       ),
//                       child: pw.Text(
//                         '$percentage%',
//                         style: pw.TextStyle(
//                           fontSize: 10,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             }).toList(),
//           ],
//         ),
//       ],
//     );
//   }

//   pw.Widget _buildTableCell(
//     String text, {
//     bool isHeader = false,
//     double fontSize = 9,
//     pw.FontWeight? fontWeight,
//     pw.Alignment? align,
//     String? subtitle,
//     int photoCount = 0,
//   }) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(6),
//       alignment: align ?? pw.Alignment.centerLeft,
//       child: pw.Column(
//         crossAxisAlignment: align == pw.Alignment.center
//             ? pw.CrossAxisAlignment.center
//             : pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             text,
//             style: pw.TextStyle(
//               fontSize: isHeader ? 10 : fontSize,
//               fontWeight: isHeader
//                   ? pw.FontWeight.bold
//                   : (fontWeight ?? pw.FontWeight.normal),
//               color: isHeader ? PdfColors.grey800 : PdfColors.black,
//             ),
//           ),
//           if (subtitle != null && subtitle.isNotEmpty) ...[
//             pw.SizedBox(height: 2),
//             pw.Text(
//               subtitle,
//               style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
//               maxLines: 20,
//             ),
//           ],
//           if (photoCount > 0) ...[
//             pw.SizedBox(height: 2),
//             pw.Text(
//               '$photoCount Fotos',
//               style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   pw.Widget _buildOverallNotes() {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           "Zusätzliche Informationen",
//           style: pw.TextStyle(
//             fontSize: 12,
//             fontWeight: pw.FontWeight.bold,
//             color: PdfColors.red700,
//           ),
//         ),
//         pw.SizedBox(height: 6),
//         pw.Container(
//           width: double.infinity,
//           padding: const pw.EdgeInsets.all(10),
//           decoration: pw.BoxDecoration(
//             color: PdfColors.grey100,
//             borderRadius: pw.BorderRadius.circular(6),
//             border: pw.Border.all(color: PdfColors.grey300),
//           ),
//           child: pw.Text(overallNotes, style: const pw.TextStyle(fontSize: 10)),
//         ),
//       ],
//     );
//   }

//   pw.Widget _buildSignaturesSection() {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [
//         _buildSignatureBox("Inspektor-Unterschrift", inspectorSignature),
//         pw.SizedBox(width: 16),
//         _buildSignatureBox("Filialvertreter", branchSignature),
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
//             style: pw.TextStyle(
//               fontSize: 9,
//               fontWeight: pw.FontWeight.bold,
//               color: PdfColors.grey700,
//             ),
//           ),
//           pw.SizedBox(height: 8),
//           pw.Container(
//             height: 60,
//             decoration: pw.BoxDecoration(
//               color: PdfColors.grey100,
//               borderRadius: pw.BorderRadius.circular(4),
//             ),
//             child: signature != null
//                 ? pw.ClipRRect(
//                     verticalRadius: 4,
//                     horizontalRadius: 4,
//                     child: pw.Image(
//                       pw.MemoryImage(signature),
//                       fit: pw.BoxFit.contain,
//                     ),
//                   )
//                 : pw.Center(
//                     child: pw.Text(
//                       "Nicht unterschrieben",
//                       style: const pw.TextStyle(
//                         fontSize: 9,
//                         color: PdfColors.grey500,
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
//       margin: const pw.EdgeInsets.only(top: 12),
//       padding: const pw.EdgeInsets.only(top: 8),
//       decoration: const pw.BoxDecoration(
//         border: pw.Border(
//           top: pw.BorderSide(color: PdfColors.grey300, width: 1),
//         ),
//       ),
//       child: pw.Text(
//         'Seite ${context.pageNumber} von ${context.pagesCount}',
//         style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
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
//             pw.Container(
//               padding: const pw.EdgeInsets.symmetric(
//                 horizontal: 8,
//                 vertical: 6,
//               ),
//               decoration: pw.BoxDecoration(
//                 color: PdfColors.grey200,
//                 borderRadius: pw.BorderRadius.circular(4),
//               ),
//               child: pw.Text(
//                 '${category.title} (${category.score}/${category.maxScore})',
//                 style: pw.TextStyle(
//                   fontSize: 12,
//                   fontWeight: pw.FontWeight.bold,
//                   color: PdfColors.red700,
//                 ),
//               ),
//             ),
//             pw.SizedBox(height: 10),
//             pw.GridView(
//               childAspectRatio: 1.0,
//               crossAxisCount: 3,
//               mainAxisSpacing: 10,
//               crossAxisSpacing: 10,
//               children: photos.map((photo) {
//                 return pw.Container(
//                   decoration: pw.BoxDecoration(
//                     border: pw.Border.all(color: PdfColors.grey400),
//                     borderRadius: pw.BorderRadius.circular(6),
//                   ),
//                   child: pw.ClipRRect(
//                     horizontalRadius: 6,
//                     verticalRadius: 6,
//                     child: pw.Image(
//                       pw.MemoryImage(photo.readAsBytesSync()),
//                       fit: pw.BoxFit.cover,
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//             pw.SizedBox(height: 16),
//           ],
//         ),
//       );
//     }

//     return widgets;
//   }

//   bool _hasPhotos() {
//     return categoryPhotos.values.any((photos) => photos.isNotEmpty);
//   }

//   Map<String, dynamic> _getPerformanceLevel(int percentage) {
//     if (percentage >= 90) {
//       return {
//         'label': "Ausgezeichnet",
//         'emoji': '😃',
//         'color': PdfColors.green700,
//       };
//     } else if (percentage >= 75) {
//       return {'label': "Gut", 'emoji': '🙂', 'color': PdfColors.lightGreen700};
//     } else if (percentage >= 60) {
//       return {
//         'label': "Befriedigend",
//         'emoji': '😐',
//         'color': PdfColors.orange700,
//       };
//     } else if (percentage >= 40) {
//       return {
//         'label': "Unterdurchschnittlich",
//         'emoji': '😕',
//         'color': PdfColors.deepOrange700,
//       };
//     } else if (percentage >= 20) {
//       return {'label': "Schlecht", 'emoji': '😞', 'color': PdfColors.red700};
//     } else {
//       return {
//         'label': "Sehr schwach",
//         'emoji': '😢',
//         'color': PdfColors.red900,
//       };
//     }
//   }
// }

// class CategoryScore {
//   final String categoryId;
//   final String title;
//   final int score;
//   final int maxScore;
//   final String notes;
//   final int photoCount;

//   CategoryScore({
//     required this.categoryId,
//     required this.title,
//     required this.score,
//     required this.maxScore,
//     this.notes = '',
//     this.photoCount = 0,
//   });
// }
