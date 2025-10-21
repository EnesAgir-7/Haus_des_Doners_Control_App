import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/firebase_services/inspector_branch_service.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/console.dart';
import '../../../models/branch_model.dart';
import '../../../models/inspection_model.dart';
import '../../../models/inspection_template_model.dart';
import '../firebase_services/inspection_pdf_generator.dart';
import '../firebase_services/inspector_inspection_service.dart';
import '../firebase_services/inspector_onedrive_service.dart';
import '../firebase_services/inspector_signature_service.dart';
import '../screens/pdf_preview.dart';
import '../widgets/custom_toast.dart';
import '../widgets/widgets_reports_screen.dart';

enum UploadStage { uploadingPhotos, uploadingPDF, submitting }

/// Provider for Control (Inspection Form) screen
/// Handles creating and submitting inspections with photo uploads
class ProviderControl extends ChangeNotifier {
  final InspectorInspectionService _inspectionService =
      InspectorInspectionService();
  final InspectorBranchService _branchService = InspectorBranchService();
  final InspectorOneDriveService _oneDriveService = InspectorOneDriveService();
  final SignatureStorageService _signatureStorage = SignatureStorageService();

  bool _isLoadingSignature = false;
  bool get isLoadingSignature => _isLoadingSignature;

  Uint8List? inspectorSignature;
  Uint8List? branchSignature;
  UploadStage? _currentUploadStage;
  UploadStage? get currentUploadStage => _currentUploadStage;
  bool _isSignatureFromStorage = false;

  bool get isSignatureFromStorage => _isSignatureFromStorage;

  // State
  BranchModel? _selectedBranch;
  InspectionTemplate? selectedTemplate;

  Map<String, int> _scores = {};
  Map<String, String> _notes = {};
  Map<String, List<File>> _photos = {};

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

  // Load signature on initialization
  Future<void> loadSavedSignature() async {
    _isLoadingSignature = true;
    notifyListeners();

    try {
      final hasSignature = await _signatureStorage.hasSignature();

      if (hasSignature) {
        inspectorSignature = await _signatureStorage.loadSignature();
        _isSignatureFromStorage = true; // ✅ Mark as loaded from storage
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved signature: $e');
    } finally {
      _isLoadingSignature = false;
      notifyListeners();
    }
  }

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
    _isSignatureFromStorage = false; // ✅ Mark as new signature
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
    loadSavedSignature();
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
  Future<bool> submitInspection(BuildContext context) async {
    if (selectedTemplate == null) {
      _errorMessage = 'No template selected.';
      notifyListeners();
      return false;
    }

    // ✅ NEW: Ask to save signature before submitting
    if (inspectorSignature != null) {
      await _askToSaveSignature(context);
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

    selectedTemplate = null;
    _isLoading = false;
    _isLoadingSignature = false;
    _currentUploadStage = null;

    inspectorSignature = null;
    branchSignature = null;
    _isSignatureFromStorage = false;
  }

  Future<void> previewPDF(BuildContext context) async {
    try {
      // Prepare category data
      final List<CategoryScore> categoryScores = selectedTemplate!.categories
          .map(
            (category) => CategoryScore(
              categoryId: category.categoryId,
              title: category.title,
              score: _scores[category.categoryId] ?? 0,
              notes: _notes[category.categoryId] ?? '',
              photoCount: (_photos[category.categoryId] ?? []).length,
            ),
          )
          .toList();

      // Create PDF generator
      final pdfGenerator = InspectionPDFGenerator(
        inspectionId: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        branchName: _selectedBranch!.name,
        branchAddress: _selectedBranch!.address,
        inspectorName: loggedInUser!.name,
        templateName: selectedTemplate?.name,
        categories: categoryScores,
        totalScore: totalScore,
        overallNotes: _overallNotes,
        inspectorSignature: inspectorSignature,
        branchSignature: branchSignature,
        categoryPhotos: _photos,
      );

      // Generate pw.Document for preview
      final pdf = await pdfGenerator.generateDocument();

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
      // Prepare category data
      final List<CategoryScore> categoryScores = selectedTemplate!.categories
          .map(
            (category) => CategoryScore(
              categoryId: category.categoryId,
              title: category.title,
              score: _scores[category.categoryId] ?? 0,
              notes: _notes[category.categoryId] ?? '',
              photoCount: (_photos[category.categoryId] ?? []).length,
            ),
          )
          .toList();

      // Create PDF generator
      final pdfGenerator = InspectionPDFGenerator(
        inspectionId: inspectionId,
        branchName: _selectedBranch!.name,
        branchAddress: _selectedBranch!.address,
        inspectorName: loggedInUser!.name,
        templateName: selectedTemplate?.name,
        categories: categoryScores,
        totalScore: totalScore,
        overallNotes: _overallNotes,
        inspectorSignature: inspectorSignature,
        branchSignature: branchSignature,
        categoryPhotos: _photos,
      );

      // Generate pw.Document
      final pw.Document pdfDocument = await pdfGenerator.generateDocument();

      // Save to file
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

  Future<void> _askToSaveSignature(BuildContext context) async {
    await showAskToSaveSignatureDialog(
      context: context,
      signatureStorage: _signatureStorage,
      inspectorSignature: inspectorSignature!,
    );
  }

  Future<void> deleteSavedSignaturePermanently(BuildContext context) async {
    await showDeleteSavedSignatureDialog(
      context: context,
      signatureStorage: _signatureStorage,
      onSignatureDeleted: () {
        inspectorSignature = null;
        _isSignatureFromStorage = false;
        notifyListeners();
      },
    );
  }
}
