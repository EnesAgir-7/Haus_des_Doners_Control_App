// lib/providers/control_provider.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/firebase_services/firebase_branch_service.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/console.dart';
import '../firebase_services/firebase_inspection_service.dart';
import '../firebase_services/onedrive_service.dart';
import '../models/branch_model.dart';
import '../models/inspection_model.dart';
import '../models/inspection_template_model.dart';
import '../screens/user/pdf_preview.dart';
import '../widgets/custom_toast.dart';

/// Provider for Control (Inspection Form) screen
/// Handles creating and submitting inspections with photo uploads
class ProviderControl extends ChangeNotifier {
  final InspectionService _inspectionService = InspectionService();
  final BranchService _branchService = BranchService();
  final OneDriveService _oneDriveService = OneDriveService();

  // State
  BranchModel? _selectedBranch;
  InspectionTemplate? selectedTemplate;

  Map<String, int> _scores = {};
  Map<String, String> _notes = {};
  Map<String, List<File>> _photos = {};

  Uint8List? inspectorSignature;
  Uint8List? branchSignature;

  // Overall notes
  String _overallNotes = '';

  // UI State
  bool _isSubmitting = false;
  bool _isUploading = false;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  BranchModel? get selectedBranch => _selectedBranch;

  String get overallNotes => _overallNotes;

  bool get isSubmitting => _isSubmitting;
  bool get isUploading => _isUploading;
  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void setTemplate(InspectionTemplate newTemplate) {
    selectedTemplate = newTemplate;
    notifyListeners();
  }

  void setBranch(BranchModel branch) {
    _selectedBranch = branch;
  }

  // Getters
  int getCategoryScore(String categoryId) => _scores[categoryId] ?? 0;

  String getCategoryNotes(String categoryId) => _notes[categoryId] ?? '';

  List<File> getCategoryPhotos(String categoryId) =>
      List.unmodifiable(_photos[categoryId] ?? []);

  // Setters
  void setCategoryScore(String categoryId, int value) {
    _scores[categoryId] = value;
    notifyListeners();
  }

  void setCategoryNotes(String categoryId, String value) {
    _notes[categoryId] = value;
  }

  void addCategoryPhoto(String categoryId, File file) {
    final list = _photos.putIfAbsent(categoryId, () => <File>[]);
    if (list.length >= 4) return; // guard: max 4 photos
    list.add(file);
    notifyListeners();
  }

  void removeCategoryPhoto(String categoryId, File file) {
    _photos[categoryId]?.remove(file);
    if (_photos[categoryId]?.isEmpty ?? false) {
      _photos.remove(categoryId);
    }
    notifyListeners();
  }

  // Optional: remove by index (if your UI prefers index-based)
  void removeCategoryPhotoAt(String categoryId, int index) {
    final list = _photos[categoryId];
    if (list == null) return;
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    if (list.isEmpty) _photos.remove(categoryId);
    notifyListeners();
  }

  // Validation
  bool get isFormValid {
    if (selectedTemplate == null) return false;
    return selectedTemplate!.categories.every(
      (cat) => _scores[cat.categoryId] != null,
    );
  }

  bool get hasAllSignatures =>
      inspectorSignature != null && branchSignature != null;

  void setInspectorSignature(Uint8List? signature) {
    inspectorSignature = signature;
    notifyListeners();
  }

  void setBranchSignature(Uint8List? signature) {
    branchSignature = signature;
    notifyListeners();
  }

  // Computed: Overall score (average of categories)
  double get totalScore => _scores.values.fold(0, (a, b) => a + b);

  // Initialize with branch and user
  void initialize(
    BranchModel? branch,
    String branchId,
    String templateId,
  ) async {
    resetForm();
    if (branch != null) {
      _selectedBranch = branch;
      await fetchTemplateByID(branch.templateId);
    } else {
      await Future.wait([
        getBranchById(branchId),
        fetchTemplateByID(templateId),
      ]);
    }
  }

  void setOverallNotes(String notes) {
    _overallNotes = notes;
    notifyListeners();
  }

  Future<bool> submitInspection() async {
    if (selectedTemplate == null) {
      _errorMessage = 'No template selected.';
      notifyListeners();
      return false;
    }

    bool allScored = selectedTemplate!.categories.every(
      (cat) => _scores[cat.categoryId] != null,
    );
    if (!allScored) {
      _errorMessage = 'Please rate all categories before submitting.';
      notifyListeners();
      return false;
    }

    try {
      _isSubmitting = true;
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      // 🔹 No OneDrive login needed anymore
      // The OneDriveService will already handle token automatically internally

      // Generate unique inspection ID
      final inspectionId = DateTime.now().millisecondsSinceEpoch.toString();

      final Map<String, List<Map<String, dynamic>>> uploadedFiles = {};
      int processedCategories = 0;

      // 🔹 Upload photos for each category to OneDrive
      for (final category in selectedTemplate!.categories) {
        final files = _photos[category.categoryId] ?? [];

        if (files.isNotEmpty) {
          final uploadedImages = await _oneDriveService.uploadImages(
            images: files,
            branchId: _selectedBranch!.id,
            inspectionId: inspectionId,
            categoryId: category.categoryId,
            onProgress: (current, total) {
              print(
                'Uploading image $current of $total for ${category.categoryId}',
              );
            },
          );

          uploadedFiles[category.categoryId] = uploadedImages;
        }

        processedCategories++;
        _uploadProgress =
            processedCategories /
            selectedTemplate!.categories.length *
            0.8; // 80% for images
        notifyListeners();
      }

      // 🔹 Generate PDF report
      final pdfFile = await generatePDFReport(inspectionId);

      // 🔹 Upload PDF to OneDrive
      final pdfUploadResult = await _oneDriveService.uploadPDFReport(
        pdfFile: pdfFile,
        branchId: _selectedBranch!.id,
        inspectionId: inspectionId,
        onProgress: (progress) {
          _uploadProgress = 0.8 + (progress * 0.2); // Last 20% for PDF
          notifyListeners();
        },
      );

      _uploadProgress = 1.0;
      _isUploading = false;
      notifyListeners();

      final now = DateTime.now();

      // 🔹 Build inspection object with OneDrive links
      final inspection = InspectionModel(
        id: inspectionId,
        branchId: _selectedBranch!.id,
        branchName: _selectedBranch!.name,
        inspectorId: loggedInUser!.id,
        inspectorName: loggedInUser!.name,
        scheduledTime: now,
        completedTime: now,
        status: AppConstants.completed,
        score: totalScore,
        categories: Map.fromEntries(
          selectedTemplate!.categories.map((cat) {
            final score = _scores[cat.categoryId] ?? 0;
            final notes = _notes[cat.categoryId] ?? '';

            final photos = (uploadedFiles[cat.categoryId] ?? [])
                .map((file) => file['downloadUrl'] as String)
                .toList();

            return MapEntry(
              cat.categoryId,
              InspectionCategoryModel(
                score: score,
                photos: photos,
                notes: notes,
              ),
            );
          }),
        ),
        overallNotes: _overallNotes,
        pdfReportUrl: pdfUploadResult['downloadUrl'],
        pdfReportWebUrl: pdfUploadResult['webUrl'],
        publicUrl: pdfUploadResult['publicUrl'],
        createdAt: now,
        updatedAt: now,
      );

      // 🔹 Save to Firestore
      await _inspectionService.createInspection(inspection);

      // Delete local PDF file
      if (await pdfFile.exists()) {
        await pdfFile.delete();
      }

      _successMessage =
          'Inspection saved successfully to OneDrive and Firestore.';
      _isSubmitting = false;
      notifyListeners();

      resetForm();

      return true;
    } catch (e, st) {
      _errorMessage =
          'An error occurred while saving inspection: ${e.toString()}';
      _isSubmitting = false;
      _isUploading = false;
      notifyListeners();
      console('Submit error: $e\n$st');
      return false;
    }
  }

  Future<void> fetchTemplateByID(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final template = await _inspectionService.getTemplateById(id);

      if (template == null) {
        _errorMessage = 'Template with ID $id not found.';
      } else {
        setTemplate(template);
      }
    } catch (e) {
      _errorMessage = 'Error loading branches: ${e.toString()}';
      console(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getBranchById(String branchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final branch = await _branchService.getBranchById(branchId);

      if (branch == null) {
        _errorMessage = 'Branch not found';
      } else {
        setBranch(branch);
      }
    } catch (e) {
      _errorMessage = 'Error loading branches: ${e.toString()}';
      console(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get isSubmittingOrUploading => _isSubmitting || _isUploading;

  void resetForm() {
    _overallNotes = '';
    _photos = {};
    _scores = {};
    _notes = {};
    _selectedBranch = null;
    _uploadProgress = 0.0;
    _errorMessage = null;
    _successMessage = null;
    _isSubmitting = false;
    _isUploading = false;
    inspectorSignature = null;
    branchSignature = null;
    // notifyListeners();
  }

  Future<void> previewPDF(BuildContext context) async {
    try {
      final pdf = await _generateInspectionPDF();

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PDFPreviewScreen(pdf: pdf, branchName: _selectedBranch!.name),
          ),
        );
      }
    } catch (e) {
      console('Error generating PDF: $e');
      if (context.mounted) {
        showSnakBarr(context, 'Error generating PDF preview');
      }
    }
  }

  Future<File> generatePDFReport(String inspectionId) async {
    try {
      // Use your existing PDF generation method
      final pw.Document pdfDocument = await _generateInspectionPDF();

      // Get temporary directory to save the file
      final directory = await getTemporaryDirectory();

      // Create unique file name
      final fileName =
          'inspection_${inspectionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Create the file
      final file = File(filePath);

      // Convert PDF document to bytes and save to file
      final bytes = await pdfDocument.save();
      await file.writeAsBytes(bytes);

      print('PDF saved to: $filePath');
      return file;
    } catch (e) {
      print('Error generating PDF file: $e');
      rethrow;
    }
  }

  Future<pw.Document> _generateInspectionPDF() async {
    final pdf = pw.Document();

    // Load logo (optional - replace with your logo path)
    final logoImage = await imageFromAssetBundle('assets/logo.png');

    // Format date
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildPDFHeader(logoImage, now, dateFormat),
          pw.SizedBox(height: 20),

          // Branch Info
          _buildBranchInfo(),
          pw.SizedBox(height: 20),

          // Inspector Info
          _buildInspectorInfo(dateFormat, now),
          pw.SizedBox(height: 20),

          // Divider
          pw.Divider(thickness: 2, color: PdfColors.red700),
          pw.SizedBox(height: 20),

          // Categories with Scores
          _buildCategoriesSection(),
          pw.SizedBox(height: 20),

          // Overall Score
          _buildOverallScore(),
          pw.SizedBox(height: 20),

          // Overall Notes
          if (_overallNotes.isNotEmpty) _buildOverallNotes(),

          pw.SizedBox(height: 30),

          // Signatures
          _buildSignaturesSection(),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    // Add photos page
    if (_hasPhotos()) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Inspection Photos',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            ..._buildPhotosSection(),
          ],
        ),
      );
    }

    return pdf;
  }

  pw.Widget _buildPDFHeader(
    pw.ImageProvider logoImage,
    DateTime now,
    DateFormat dateFormat,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(logoImage, width: 80, height: 80),
            pw.SizedBox(height: 8),
            pw.Text(
              'INSPECTION REPORT',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red700,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              LocaleKeys.report_id.tr(),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              '#${now.millisecondsSinceEpoch.toString().substring(7)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              dateFormat.format(now),
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBranchInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.red700, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Icon(
                  const pw.IconData(0xe0c8), // location_on icon
                  color: PdfColors.white,
                  size: 20,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                LocaleKeys.branch_information.tr(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            _selectedBranch!.name,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _selectedBranch!.address,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInspectorInfo(DateFormat dateFormat, DateTime now) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Inspector',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                loggedInUser!.name,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Template',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                selectedTemplate?.name ?? 'N/A',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
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
          LocaleKeys.inspection_details.tr(),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red700,
          ),
        ),
        pw.SizedBox(height: 16),
        ...selectedTemplate!.categories.map((category) {
          final score = _scores[category.categoryId] ?? 0;
          final notes = _notes[category.categoryId] ?? '';
          final photos = _photos[category.categoryId] ?? [];

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        category.title,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _getScoreColor(score),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        '$score/4',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      notes,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
                if (photos.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${photos.length} photo(s) attached',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildOverallScore() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.red700, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                LocaleKeys.total_score.tr(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                totalScore.toStringAsFixed(1),
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                ),
              ),
            ],
          ),
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColors.red700,
            ),
            child: pw.Center(
              child: pw.Icon(
                const pw.IconData(0xe838), // star icon
                color: PdfColors.white,
                size: 40,
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
          LocaleKeys.overall_notes.tr(),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red700,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            _overallNotes,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSignaturesSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignatureBox(
          LocaleKeys.inspector_signature.tr(),
          inspectorSignature,
        ),
        pw.SizedBox(width: 20),
        _buildSignatureBox(
          LocaleKeys.branch_representative.tr(),
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
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 80,

            child: signature != null
                ? pw.ClipRRect(
                    verticalRadius: 8,
                    horizontalRadius: 8,
                    child: pw.Image(
                      pw.MemoryImage(signature),
                      fit: pw.BoxFit.contain,
                    ),
                  )
                : pw.Center(
                    child: pw.Text(
                      LocaleKeys.no_signature.tr(),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
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
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  List<pw.Widget> _buildPhotosSection() {
    final List<pw.Widget> widgets = [];

    for (final category in selectedTemplate!.categories) {
      final photos = _photos[category.categoryId];
      if (photos == null || photos.isEmpty) continue;

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              category.title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red700,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.GridView(
              childAspectRatio: 1.0, // Add this line
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: photos.map((photo) {
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(
                      pw.MemoryImage(photo.readAsBytesSync()),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],
        ),
      );
    }

    return widgets;
  }

  bool _hasPhotos() {
    return _photos.values.any((photos) => photos.isNotEmpty);
  }

  PdfColor _getScoreColor(int score) {
    switch (score) {
      case 1: // very good
        return PdfColors.green700;
      case 2: // good
        return PdfColors.blue700;
      case 3: // bad
        return PdfColors.orange700;
      case 4: // very bad
        return PdfColors.red700;
      default:
        return PdfColors.grey600;
    }
  }
}

  // Future<bool> submitInspection() async {
  //   if (selectedTemplate == null) {
  //     _errorMessage = 'No template selected.';
  //     notifyListeners();
  //     return false;
  //   }

  //   // Validate that all categories have scores
  //   bool allScored = selectedTemplate!.categories.every(
  //     (cat) => _scores[cat.categoryId] != null,
  //   );
  //   if (!allScored) {
  //     _errorMessage = 'Please rate all categories before submitting.';
  //     notifyListeners();
  //     return false;
  //   }

  //   try {
  //     _isSubmitting = true;
  //     _isUploading = true;
  //     _uploadProgress = 0.0;
  //     _errorMessage = null;
  //     _successMessage = null;
  //     notifyListeners();

  //     final userId = FirebaseAuth.instance.currentUser?.uid;
  //     if (userId == null) throw Exception('User not authenticated');

  //     final Map<String, List<String>> uploadedUrls = {};

  //     for (int i = 0; i < selectedTemplate!.categories.length; i++) {
  //       final category = selectedTemplate!.categories[i];

  //       final files = _photos[category.categoryId] ?? [];

  //       // Upload photos for this category
  //       uploadedUrls[category.categoryId] = await _uploadCategoryPhotos(
  //         files,
  //         _selectedBranch!.id,
  //         category.categoryId,
  //       );

  //       // Update progress
  //       _uploadProgress = (i + 1) / selectedTemplate!.categories.length;
  //       notifyListeners();
  //     }

  //     _isUploading = false;
  //     notifyListeners();

  //     final now = DateTime.now();

  //     // Build inspection object dynamically
  //     final inspection = InspectionModel(
  //       id: '', // Firestore will generate
  //       branchId: _selectedBranch!.id,
  //       branchName: _selectedBranch!.name,
  //       inspectorId: userId,
  //       inspectorName: loggedInUser!.name,
  //       scheduledTime: now,
  //       completedTime: now,
  //       status: AppConstants.completed,
  //       score: totalScore,
  //       categories: Map.fromEntries(
  //         selectedTemplate!.categories.map((cat) {
  //           final score = _scores[cat.categoryId] ?? 0;
  //           final notes = _notes[cat.categoryId] ?? '';
  //           final photos = uploadedUrls[cat.categoryId] ?? [];
  //           return MapEntry(
  //             cat.categoryId,
  //             InspectionCategoryModel(
  //               score: score,
  //               photos: photos,
  //               notes: notes,
  //             ),
  //           );
  //         }),
  //       ),
  //       overallNotes: _overallNotes,
  //       createdAt: now,
  //       updatedAt: now,
  //     );

  //     // Save to Firestore
  //     await _inspectionService.createInspection(inspection);

  //     _successMessage = 'Inspection saved successfully.';
  //     _isSubmitting = false;
  //     notifyListeners();

  //     resetForm();

  //     return true;
  //   } catch (e, st) {
  //     _errorMessage =
  //         'An error occurred while saving inspection: ${e.toString()}';
  //     _isSubmitting = false;
  //     _isUploading = false;
  //     notifyListeners();
  //     console('Submit error: $e\n$st');
  //     return false;
  //   }
  // }