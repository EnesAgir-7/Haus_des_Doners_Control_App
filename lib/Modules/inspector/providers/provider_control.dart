// lib/providers/control_provider.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/Modules/inspector/firebase_services/inspector_branch_service.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/console.dart';
import '../firebase_services/inspector_inspection_service.dart';
import '../firebase_services/inspector_onedrive_service.dart';
import '../../../models/branch_model.dart';
import '../../../models/inspection_model.dart';
import '../../../models/inspection_template_model.dart';
import '../screens/pdf_preview.dart';
import '../widgets/custom_toast.dart';

enum UploadStage { uploadingPhotos, uploadingPDF, submitting }

/// Provider for Control (Inspection Form) screen
/// Handles creating and submitting inspections with photo uploads
class ProviderControl extends ChangeNotifier {
  final InspectorInspectionService _inspectionService =
      InspectorInspectionService();
  final InspectorBranchService _branchService = InspectorBranchService();
  final InspectorOneDriveService _oneDriveService = InspectorOneDriveService();

  UploadStage? _currentUploadStage;
  UploadStage? get currentUploadStage => _currentUploadStage;

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

  // Update submitInspection method:
  Future<bool> submitInspection() async {
    if (selectedTemplate == null) {
      _errorMessage = 'No template selected.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _isUploading = true;
    _uploadProgress = 0.0;
    _currentUploadStage = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final inspectionId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    try {
      // 🔹 Check if there are any photos to upload
      final hasPhotos = selectedTemplate!.categories.any((category) {
        final files = _photos[category.categoryId] ?? [];
        return files.isNotEmpty;
      });

      Map<String, List<String>> uploadedUrls = {};

      if (hasPhotos) {
        // ✅ Set stage to uploading photos
        _currentUploadStage = UploadStage.uploadingPhotos;
        notifyListeners();

        // 🔹 Upload all category images first
        final categoryUploadFutures = selectedTemplate!.categories.map((
          category,
        ) async {
          final files = _photos[category.categoryId] ?? [];

          // ✅ Return early if no files - skip all uploads
          if (files.isEmpty) {
            return MapEntry(category.categoryId, <String>[]);
          }

          // ✅ Only upload if files exist
          final results = await Future.wait([
            _oneDriveService.uploadImages(
              images: files,
              branchName: _selectedBranch!.name,
              inspectionId: inspectionId,
              timestamp: now,
              onProgress: (current, total) {
                // Update progress for photo uploads (0% - 50%)
                _uploadProgress = 0.5 * (current / total);
                notifyListeners();
              },
            ),
            _uploadCategoryPhotos(
              files,
              _selectedBranch!.name,
              category.categoryId,
              inspectionId,
              now,
            ),
          ]);

          return MapEntry(category.categoryId, results[1] as List<String>);
        }).toList();

        uploadedUrls = Map.fromEntries(
          await Future.wait(categoryUploadFutures),
        );
        _uploadProgress = 0.5;
        notifyListeners();
      }

      // ✅ Set stage to uploading PDF
      _currentUploadStage = UploadStage.uploadingPDF;
      _uploadProgress = hasPhotos ? 0.5 : 0.0;
      notifyListeners();

      // 🔹 Generate and upload PDF
      final pdfFile = await generatePDFReport(inspectionId);
      final pdfUploads = await Future.wait([
        _oneDriveService.uploadPDFReport(
          pdfFile: pdfFile,
          branchName: _selectedBranch!.name,
          inspectionId: inspectionId,
          timestamp: now,
          onProgress: (progress) {
            // Update progress for PDF upload (50% - 75%)
            _uploadProgress = (hasPhotos ? 0.5 : 0.0) + (0.25 * progress);
            notifyListeners();
          },
        ),
        _uploadPDFToFirebase(pdfFile, _selectedBranch!.name, inspectionId, now),
      ]);

      final firebasePdfUrl = pdfUploads[1] as String;
      _uploadProgress = hasPhotos ? 0.75 : 0.25;
      notifyListeners();

      // ✅ Set stage to submitting inspection
      _currentUploadStage = UploadStage.submitting;
      _uploadProgress = hasPhotos ? 0.8 : 0.5;
      notifyListeners();

      // 🔹 Only after all uploads succeeded, create inspection object
      final inspection = InspectionModel(
        id: inspectionId,
        branchId: _selectedBranch!.id,
        branchName: _selectedBranch!.name,
        inspectorId: loggedInUser!.id,
        inspectorName: loggedInUser!.name,
        scheduledTime: _selectedBranch!.stop!.timeSlot.toString(),
        completedTime: now,
        status: AppConstants.completed,
        score: totalScore,
        categories: Map.fromEntries(
          selectedTemplate!.categories.map((cat) {
            final score = _scores[cat.categoryId] ?? 0;
            final notes = _notes[cat.categoryId] ?? '';
            final photos = uploadedUrls[cat.categoryId] ?? [];
            return MapEntry(
              cat.title,
              InspectionCategoryModel(
                score: score,
                photos: photos,
                notes: notes,
              ),
            );
          }),
        ),
        overallNotes: _overallNotes,
        pdfReportUrl: firebasePdfUrl,
        createdAt: now,
        updatedAt: now,
      );

      // 🔹 Save to Firestore atomically
      await _inspectionService.createInspection(inspection);

      // 🔹 Cleanup local PDF
      if (await pdfFile.exists()) await pdfFile.delete();

      _uploadProgress = 1.0;
      _isUploading = false;
      _isSubmitting = false;
      _currentUploadStage = null;
      _successMessage =
          'Inspection saved successfully to OneDrive, Firebase, and Firestore.';
      notifyListeners();

      resetForm();
      return true;
    } catch (e, st) {
      _errorMessage =
          'An error occurred while saving inspection: ${e.toString()}';
      _isSubmitting = false;
      _isUploading = false;
      _currentUploadStage = null;
      notifyListeners();
      console('Submit error: $e\n$st');
      return false;
    }
  }

  // Helper method to get month folder name (e.g., "2025-10" or "October-2025")
  String _getMonthFolder(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    // Or use: DateFormat('MMMM-yyyy').format(date); // e.g., "October-2025"
  }

  // Upload single photo to Firebase Storage
  Future<String> _uploadPhoto(File photo, String path) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final uploadTask = storageRef.putFile(photo);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      console('Error uploading photo: $e');
      rethrow;
    }
  }

  // Upload all photos for a category with structured path
  Future<List<String>> _uploadCategoryPhotos(
    List<File> photos,
    String branchName,
    String categoryId,
    String inspectionId,
    DateTime timestamp,
  ) async {
    final monthFolder = _getMonthFolder(timestamp);

    // Upload all photos concurrently
    final uploadFutures = photos.asMap().entries.map((entry) {
      final index = entry.key;
      final photo = entry.value;

      // Structure: inspections/{branchName}/{month}/{inspectionId}/{categoryId}_{index}.jpg
      final path =
          'inspections/$branchName/$monthFolder/$inspectionId/${categoryId}_$index.jpg';

      return _uploadPhoto(photo, path);
    }).toList();

    // Wait for all uploads to complete
    final urls = await Future.wait(uploadFutures);

    return urls;
  }

  // Upload PDF to Firebase Storage with structured path
  Future<String> _uploadPDFToFirebase(
    File pdfFile,
    String branchName,
    String inspectionId,
    DateTime timestamp,
  ) async {
    final monthFolder = _getMonthFolder(timestamp);

    // Structure: pdf-reports/{branchName}/{month}/{inspectionId}_report.pdf
    final path =
        'pdf-reports/$branchName/$monthFolder/${inspectionId}_report.pdf';

    final storageRef = FirebaseStorage.instance.ref().child(path);
    final uploadTask = storageRef.putFile(pdfFile);

    await uploadTask;

    return await storageRef.getDownloadURL();
  }

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






/////////////
///Future<bool> submitInspection() async {
  //   if (selectedTemplate == null) {
  //     _errorMessage = 'No template selected.';
  //     notifyListeners();
  //     return false;
  //   }

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
  //     // Generate unique inspection ID
  //     final inspectionId = DateTime.now().millisecondsSinceEpoch.toString();
  //     final now = DateTime.now();

  //     // 🔹 Upload images to both OneDrive and Firebase concurrently
  //     final categoryUploadFutures = selectedTemplate!.categories.map((
  //       category,
  //     ) async {
  //       final files = _photos[category.categoryId] ?? [];

  //       if (files.isEmpty) {
  //         return MapEntry(category.categoryId, <String>[]);
  //       }

  //       // Upload to both services concurrently
  //       final results = await Future.wait([
  //         // OneDrive upload (no need to store URLs)
  //         _oneDriveService.uploadImages(
  //           images: files,
  //           branchName: _selectedBranch!.name,
  //           inspectionId: inspectionId,
  //           timestamp: now,
  //           onProgress: (a, b) {},
  //         ),
  //         // Firebase upload (store these URLs)
  //         _uploadCategoryPhotos(
  //           files,
  //           _selectedBranch!.name,
  //           category.categoryId,
  //           inspectionId,
  //           now,
  //         ),
  //       ]);

  //       // Return Firebase URLs (results[1])
  //       return MapEntry(category.categoryId, results[1] as List<String>);
  //     }).toList();

  //     // Wait for all category uploads to complete
  //     final uploadedUrls = Map.fromEntries(
  //       await Future.wait(categoryUploadFutures),
  //     );

  //     _uploadProgress = 0.8; // 80% for images
  //     notifyListeners();

  //     // 🔹 Generate PDF report
  //     final pdfFile = await generatePDFReport(inspectionId);

  //     // 🔹 Upload PDF to both OneDrive and Firebase concurrently
  //     final pdfUploads = await Future.wait([
  //       // OneDrive PDF upload
  //       _oneDriveService.uploadPDFReport(
  //         pdfFile: pdfFile,
  //         branchName: _selectedBranch!.name,
  //         inspectionId: inspectionId,
  //         timestamp: now,
  //         onProgress: (v) {},
  //       ),
  //       // Firebase PDF upload
  //       _uploadPDFToFirebase(pdfFile, _selectedBranch!.name, inspectionId, now),
  //     ]);

  //     final firebasePdfUrl = pdfUploads[1] as String;

  //     _uploadProgress = 1.0;
  //     _isUploading = false;
  //     notifyListeners();

  //     // 🔹 Build inspection object with Firebase URLs
  //     final inspection = InspectionModel(
  //       id: inspectionId,
  //       branchId: _selectedBranch!.id,
  //       branchName: _selectedBranch!.name,
  //       inspectorId: loggedInUser!.id,
  //       inspectorName: loggedInUser!.name,
  //       scheduledTime: _selectedBranch!.stop!.timeSlot.toString(),
  //       completedTime: now,
  //       status: AppConstants.completed,
  //       score: totalScore,
  //       categories: Map.fromEntries(
  //         selectedTemplate!.categories.map((cat) {
  //           final score = _scores[cat.categoryId] ?? 0;
  //           final notes = _notes[cat.categoryId] ?? '';
  //           final photos = uploadedUrls[cat.categoryId] ?? [];

  //           return MapEntry(
  //             cat.title,
  //             InspectionCategoryModel(
  //               score: score,
  //               photos: photos,
  //               notes: notes,
  //             ),
  //           );
  //         }),
  //       ),
  //       overallNotes: _overallNotes,
  //       pdfReportUrl: firebasePdfUrl,
  //       createdAt: now,
  //       updatedAt: now,
  //     );

  //     // 🔹 Save to Firestore
  //     await _inspectionService.createInspection(inspection);

  //     // Delete local PDF file
  //     if (await pdfFile.exists()) {
  //       await pdfFile.delete();
  //     }

  //     _successMessage =
  //         'Inspection saved successfully to OneDrive, Firebase, and Firestore.';
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