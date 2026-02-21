import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:haus_des_control/Modules/inspector/firebase_services/inspector_branch_service.dart';
import 'package:haus_des_control/common_services/crashlytics_service.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/console.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums.dart';
import '../../../helpers/app_helpers.dart';
import '../../../models/branch_model.dart';
import '../../../models/inspection_model.dart';
import '../../../models/inspection_template_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../firebase_services/inspection_pdf_generator.dart';
import '../firebase_services/inspector_inspection_service.dart';
import '../firebase_services/inspector_onedrive_service.dart';
import '../firebase_services/inspector_signature_service.dart';
import '../screens/pdf_preview.dart';
import '../widgets/custom_toast.dart';
import '../widgets/widgets_reports_screen.dart';

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
  bool shouldCompressImages = true;

  bool get isSignatureFromStorage => _isSignatureFromStorage;

  // State
  BranchModel? _selectedBranch;
  InspectionTemplate? selectedTemplate;

  Map<String, int> _scores = {};
  Map<String, String> _notes = {};
  Map<String, List<File>> _photos = {};
  Map<String, bool> _enabledCategories =
      {}; // Track which questions are enabled

  // Overall notes
  String _overallNotes = '';
  String? _branchRepresentativeName;

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
  String? get branchRepresentativeName => _branchRepresentativeName;

  bool get isSubmitting => _isSubmitting;
  bool get isUploading => _isUploading;
  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

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

  setImageCompressor(bool value) {
    shouldCompressImages = value;
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
    notifyListeners();
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
    // Only validate enabled categories
    return selectedTemplate!.categories.every((cat) {
      final categoryId = cat.categoryId;
      final isEnabled = _enabledCategories[categoryId] ?? true;

      // If disabled, skip validation for this category
      if (!isEnabled) return true;

      // If enabled, must have a score selected
      return _scores[categoryId] != null && _scores[categoryId]! > 0;
    });
  }

  // Method to set enabled/disabled categories from UI
  void setEnabledCategories(Map<String, bool> enabledCategories) {
    _enabledCategories = Map.from(enabledCategories);
    notifyListeners();
  }

  bool get isSubmittingOrUploading => _isSubmitting || _isUploading;

  bool get hasAllSignatures =>
      inspectorSignature != null && branchSignature != null;

  void setInspectorSignature(Uint8List? signature) {
    inspectorSignature = signature;
    _isSignatureFromStorage = false;
    notifyListeners();
  }

  void setBranchSignature(Uint8List? signature) {
    branchSignature = signature;
    notifyListeners();
  }

  double get totalScore {
    if (selectedTemplate == null) return 0;
    return selectedTemplate!.categories.fold<double>(0.0, (sum, cat) {
      final isEnabled = _enabledCategories[cat.categoryId] ?? true;
      if (!isEnabled) return sum;
      final score = _scores[cat.categoryId] ?? 0;
      return sum + mapScoreToPoints(score);
    });
  }

  String get scoreDisplay => '${totalScore.toInt()}/$maxPossibleScore';

  int get maxPossibleScore {
    if (selectedTemplate == null) return 0;
    return selectedTemplate!.categories.fold(0, (sum, category) {
      final isEnabled = _enabledCategories[category.categoryId] ?? true;
      if (!isEnabled) return sum;
      return sum + 100;
    });
  }

  void setOverallNotes(String notes) {
    _overallNotes = notes;
    notifyListeners();
  }

  void setBranchRepresentativeName(String? name) {
    _branchRepresentativeName = name;
    notifyListeners();
  }

  Future<void> fetchTemplateByID(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final template = await _inspectionService.getTemplateById(id);

      if (template == null) {
        _errorMessage = LocaleKeys.templateNotFound.tr().replaceFirst(
          '{id}',
          id,
        );
      } else {
        setTemplate(template);
      }
    } catch (e) {
      _errorMessage =
          '${LocaleKeys.errorLoadingBranches.tr()}: ${e.toString()}';
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
        _errorMessage = LocaleKeys.branchNotFound.tr();
      } else {
        setBranch(branch);
      }
    } catch (e) {
      _errorMessage =
          '${LocaleKeys.errorLoadingBranches.tr()}: ${e.toString()}';
      console(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update submitInspection method:
  Future<bool> submitInspection(BuildContext context) async {
    if (selectedTemplate == null) {
      _errorMessage = LocaleKeys.noTemplateSelected.tr();
      notifyListeners();
      return false;
    }

    // ✅ Ask to save signature before submitting
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

      if (hasPhotos) {
        // ✅ Compress images first if enabled
        if (shouldCompressImages) {
          await compressAllImages();
        }

        // ✅ Set stage to uploading photos
        _currentUploadStage = UploadStage.uploadingPhotos;
        notifyListeners();

        // ✅ Pre-create the directory structure once to avoid race conditions
        // in the concurrent category uploads below.
        await _oneDriveService.createImagesFolder(_selectedBranch!.name, now);

        // 🔹 Upload all category images to OneDrive with error handling
        final List<String> failedCategories = [];

        await Future.wait(
          selectedTemplate!.categories.map((category) async {
            final files = _photos[category.categoryId] ?? [];

            // ✅ Return early if no files - skip upload
            if (files.isEmpty) return;

            try {
              // ✅ Upload to OneDrive
              await _oneDriveService.uploadImages(
                images: files,
                branchName: _selectedBranch!.name,
                inspectionId: inspectionId,
                timestamp: now,
                onProgress: (current, total) {
                  // Update progress for photo uploads
                  // If compressed: 25% - 62.5%, otherwise 0% - 50%
                  final baseProgress = shouldCompressImages ? 0.25 : 0.0;
                  final progressRange = shouldCompressImages ? 0.375 : 0.5;
                  _uploadProgress =
                      baseProgress + (progressRange * (current / total));
                  notifyListeners();
                },
              );
              print(
                '✅ Category "${category.title}" images uploaded successfully',
              );
            } catch (e, st) {
              // Log but don't throw - allow other uploads to continue
              print(
                '❌ Failed to upload images for category "${category.title}": $e',
              );
              debugPrintStack(label: 'Category Upload Error', stackTrace: st);
              failedCategories.add(category.title);
              // Report to Crashlytics
              CrashlyticsService().logError(
                e,
                st,
                reason:
                    'Failed to upload images for category: ${category.title}',
                fatal: false,
              );
            }
          }).toList(),
          eagerError: false, // Don't stop on first error - continue all uploads
        );

        // Check if any uploads failed
        if (failedCategories.isNotEmpty) {
          throw Exception(
            'Failed to upload images for categories: ${failedCategories.join(", ")}. '
            'Please check your internet connection and try again.',
          );
        }

        _uploadProgress = shouldCompressImages ? 0.625 : 0.5;
        notifyListeners();
      }

      // ✅ Set stage to uploading PDF
      _currentUploadStage = UploadStage.uploadingPDF;
      final baseProgressForPdf = hasPhotos
          ? (shouldCompressImages ? 0.625 : 0.5)
          : 0.0;
      _uploadProgress = baseProgressForPdf;
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
            // Update progress for PDF upload
            final progressRange = shouldCompressImages && hasPhotos
                ? 0.25
                : 0.25;
            _uploadProgress = baseProgressForPdf + (progressRange * progress);
            notifyListeners();
          },
        ),
        _uploadPDFToFirebase(pdfFile, _selectedBranch!.name, inspectionId, now),
      ]);

      final firebasePdfUrl = pdfUploads[1] as String;
      _uploadProgress = shouldCompressImages && hasPhotos
          ? 0.875
          : (hasPhotos ? 0.75 : 0.25);
      notifyListeners();

      // ✅ Set stage to submitting inspection
      _currentUploadStage = UploadStage.submitting;
      _uploadProgress = shouldCompressImages && hasPhotos
          ? 0.9
          : (hasPhotos ? 0.8 : 0.5);
      notifyListeners();

      final scoreString = '${totalScore.toInt()}/$maxPossibleScore';

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
        score: scoreString,
        categories: Map.fromEntries(
          selectedTemplate!.categories.map((cat) {
            final categoryId = cat.categoryId;
            final isEnabled = _enabledCategories[categoryId] ?? true;
            final score = _scores[categoryId] ?? 0;
            final notes = _notes[categoryId] ?? '';

            // Mark category as skipped if disabled
            if (!isEnabled) {
              return MapEntry(
                cat.title,
                InspectionCategoryModel(
                  score: "N/A",
                  notes: "Not Applicable - Question Skipped",
                ),
              );
            }

            return MapEntry(
              cat.title,
              InspectionCategoryModel(
                score: "$score/5", // Store raw mark (1-5)
                notes: notes,
              ),
            );
          }),
        ),
        branchRepresentativeName: _branchRepresentativeName,
        overallNotes: _overallNotes,
        pdfReportUrl: firebasePdfUrl,
        createdAt: now,
        updatedAt: now,
      );

      // 🔹 Save to Firestore atomically
      await _inspectionService.createInspection(
        inspection,
        _selectedBranch?.fcmTokens ?? [],
      );

      // 🔹 Cleanup local PDF
      if (await pdfFile.exists()) await pdfFile.delete();

      _uploadProgress = 1.0;
      _isUploading = false;
      _isSubmitting = false;
      _currentUploadStage = null;
      _successMessage = LocaleKeys.inspectionSavedSuccess.tr();

      notifyListeners();

      resetForm();
      return true;
    } catch (e, st) {
      debugPrintStack(label: 'Submit Inspection Error', stackTrace: st);

      // Determine what stage failed for better error reporting
      String failureStage = 'Unknown';
      if (_currentUploadStage == UploadStage.compressingImages) {
        failureStage = 'Image Compression';
      } else if (_currentUploadStage == UploadStage.uploadingPhotos) {
        failureStage = 'Photo Upload';
      } else if (_currentUploadStage == UploadStage.uploadingPDF) {
        failureStage = 'PDF Upload';
      } else if (_currentUploadStage == UploadStage.submitting) {
        failureStage = 'Firestore Submission';
      }

      _errorMessage = 'Error during $failureStage: ${e.toString()}';

      // Log detailed error for debugging
      print('❌ Inspection submission failed');
      print('📍 Stage: $failureStage');
      print('🔴 Error: $e');
      print('📚 Stack trace: $st');

      // Report to Crashlytics
      CrashlyticsService().logError(
        e,
        st,
        reason: 'Inspection submission failed at stage: $failureStage',
        fatal: false,
      );

      _isSubmitting = false;
      _isUploading = false;
      _currentUploadStage = null;
      notifyListeners();
      return false;
    }
  }

  // ✅ Compress all images that haven't been compressed yet
  Future<void> compressAllImages() async {
    if (selectedTemplate == null || !shouldCompressImages) return;

    _currentUploadStage = UploadStage.compressingImages;
    _uploadProgress = 0.0;
    notifyListeners();

    int totalImages = 0;
    int processedImages = 0;

    // Count total images
    for (var category in selectedTemplate!.categories) {
      final files = _photos[category.categoryId] ?? [];
      totalImages += files.length;
    }

    if (totalImages == 0) {
      _currentUploadStage = null;
      notifyListeners();
      return;
    }

    // Compress images
    for (var category in selectedTemplate!.categories) {
      final files = _photos[category.categoryId] ?? [];

      if (files.isEmpty) continue;

      List<File> compressedFiles = [];

      for (var file in files) {
        // Skip if already compressed
        if (file.path.contains('_compressed.jpg')) {
          compressedFiles.add(file);
        } else {
          // Compress the image
          final compressedFile = await compressImage(file);
          compressedFiles.add(compressedFile);
        }

        processedImages++;
        // Update progress for compression (0% - 25%)
        _uploadProgress = 0.25 * (processedImages / totalImages);
        notifyListeners();
      }

      // Replace original files with compressed files
      _photos[category.categoryId] = compressedFiles;
    }

    _currentUploadStage = null;
    notifyListeners();
  }

  // ✅ Helper method to compress a single image
  Future<File> compressImage(File imageFile) async {
    try {
      // Compress with timeout to prevent hanging
      final compressedBytes =
          await FlutterImageCompress.compressWithFile(
            imageFile.absolute.path,
            quality: 65, // Balanced compression for smaller size
            minWidth: 1600,
            minHeight: 900,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⚠️ Image compression timed out after 30s, using original');
              return null;
            },
          );

      if (compressedBytes == null) {
        print('⚠️ Compression returned null, using original file');
        return imageFile;
      }

      // Save compressed image to a temp file
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );
      await compressedFile.writeAsBytes(compressedBytes);

      // Verify compressed file is actually smaller
      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();

      if (compressedSize >= originalSize) {
        print('ℹ️ Compressed file not smaller, using original');
        await compressedFile.delete();
        return imageFile;
      }

      print(
        '✅ Compressed ${(originalSize / 1024).toStringAsFixed(1)}KB → ${(compressedSize / 1024).toStringAsFixed(1)}KB',
      );
      return compressedFile;
    } catch (e, st) {
      print('❌ Error compressing image: $e');
      debugPrintStack(label: 'Image Compression Error', stackTrace: st);
      // Report to Crashlytics but don't fail the upload
      CrashlyticsService().logError(
        e,
        st,
        reason: 'Image compression failed',
        fatal: false,
      );
      return imageFile; // Return original if compression fails - don't crash
    }
  }

  // Helper method to get month folder name (e.g., "2025-10" or "October-2025")
  String _getMonthFolder(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    // Or use: DateFormat('MMMM-yyyy').format(date); // e.g., "October-2025"
  }

  // Upload single photo to Firebase Storage
  // Future<String> _uploadPhoto(File photo, String path) async {
  //   try {
  //     final storageRef = FirebaseStorage.instance.ref().child(path);
  //     final uploadTask = storageRef.putFile(photo);

  //     final snapshot = await uploadTask;
  //     final downloadUrl = await snapshot.ref.getDownloadURL();

  //     return downloadUrl;
  //   } catch (e) {
  //     console('Error uploading photo: $e');
  //     rethrow;
  //   }
  // }

  // Upload all photos for a category with structured path
  // Future<List<String>> _uploadCategoryPhotos(
  //   List<File> photos,
  //   String branchName,
  //   String categoryId,
  //   String inspectionId,
  //   DateTime timestamp,
  // ) async {
  //   final monthFolder = _getMonthFolder(timestamp);

  //   // Upload all photos concurrently
  //   final uploadFutures = photos.asMap().entries.map((entry) {
  //     final index = entry.key;
  //     final photo = entry.value;

  //     // Structure: inspections/{branchName}/{month}/{inspectionId}/{categoryId}_{index}.jpg
  //     final path =
  //         'inspections/$branchName/$monthFolder/$inspectionId/${categoryId}_$index.jpg';

  //     return _uploadPhoto(photo, path);
  //   }).toList();

  //   // Wait for all uploads to complete
  //   final urls = await Future.wait(uploadFutures);

  //   return urls;
  // }

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
    _branchRepresentativeName = null;
    _enabledCategories = {}; // Reset enabled categories
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
      // ✅ Compress images before preview if enabled
      if (shouldCompressImages) {
        final hasPhotos = selectedTemplate!.categories.any((category) {
          final files = _photos[category.categoryId] ?? [];
          return files.isNotEmpty;
        });

        if (hasPhotos) {
          _isUploading = true; // Show loading while compressing
          notifyListeners();
          await compressAllImages();
          _isUploading = false;
          notifyListeners();
        }
      }

      // Prepare category data using points (0-100) instead of raw marks (1-5)
      final List<CategoryScore> categoryScores = selectedTemplate!.categories
          .map((category) {
            final categoryId = category.categoryId;
            final isEnabled = _enabledCategories[categoryId] ?? true;
            final isSkipped = !isEnabled; // Question is skipped if disabled
            final mark = _scores[categoryId] ?? 0;

            return CategoryScore(
              maxScore: 100, // Show points scale
              categoryId: categoryId,
              title: category.title,
              score: mapScoreToPoints(mark), // Convert mark to points
              notes: _notes[categoryId] ?? '',
              photoCount: (_photos[categoryId] ?? []).length,
              isSkipped: isSkipped, // Mark as skipped if disabled
            );
          })
          .toList();

      final enabledScore = totalScore;
      final enabledMaxScore = maxPossibleScore.toDouble();

      // Create PDF generator
      final pdfGenerator = InspectionPDFGenerator(
        maxPossibleScore: enabledMaxScore,
        inspectionId: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        branchName: _selectedBranch!.name,
        branchAddress: _selectedBranch!.address,
        inspectorName: loggedInUser!.name,
        templateName: selectedTemplate?.name,
        categories: categoryScores,
        totalScore: enabledScore,
        overallNotes: _overallNotes,
        inspectorSignature: inspectorSignature,
        branchSignature: branchSignature,
        categoryPhotos: _photos,
        enabledCategories: _enabledCategories,
        branchRepresentativeName: _branchRepresentativeName,
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
        showSnakBarr(context, LocaleKeys.errorGeneratingPDF.tr());
      }
    }
  }

  Future<File> generatePDFReport(String inspectionId) async {
    try {
      // Prepare category data
      final List<CategoryScore> categoryScores = selectedTemplate!.categories
          .map((category) {
            final categoryId = category.categoryId;
            final isEnabled = _enabledCategories[categoryId] ?? true;
            final isSkipped = !isEnabled; // Question is skipped if disabled

            return CategoryScore(
              maxScore: 100,
              categoryId: category.categoryId,
              title: category.title,
              score: mapScoreToPoints(_scores[categoryId] ?? 0),
              notes: _notes[categoryId] ?? '',
              photoCount: (_photos[categoryId] ?? []).length,
              isSkipped: isSkipped, // Mark as skipped if disabled
            );
          })
          .toList();

      // Use consistent points-based getters for header
      final enabledScore = totalScore;
      final enabledMaxScore = maxPossibleScore.toDouble();

      // Create PDF generator
      final pdfGenerator = InspectionPDFGenerator(
        maxPossibleScore: enabledMaxScore,
        inspectionId: inspectionId,
        branchName: _selectedBranch!.name,
        branchAddress: _selectedBranch!.address,
        inspectorName: loggedInUser!.name,
        templateName: selectedTemplate?.name,
        categories: categoryScores,
        totalScore: enabledScore,
        overallNotes: _overallNotes,
        inspectorSignature: inspectorSignature,
        branchSignature: branchSignature,
        categoryPhotos: _photos,
        enabledCategories: _enabledCategories,
        branchRepresentativeName: _branchRepresentativeName,
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
