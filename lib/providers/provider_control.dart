// lib/providers/control_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../core/console.dart';
import '../firebase_services/firebase_inspection_service.dart';
import '../models/inspection_model.dart';
import '../models/branch_model.dart';
import '../models/inspection_template_model.dart';
import '../models/user_model.dart';

/// Provider for Control (Inspection Form) screen
/// Handles creating and submitting inspections with photo uploads
class ProviderControl extends ChangeNotifier {
  final InspectionService _inspectionService = InspectionService();

  // State
  BranchModel? _selectedBranch;
  UserModel? _currentUser;
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
  UserModel? get currentUser => _currentUser;

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
    console(_notes);
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

  // Computed: Overall score (average of categories)
  double get totalScore => _scores.values.fold(0, (a, b) => a + b);

  // Initialize with branch and user
  void initialize(BranchModel branch) {
    resetForm();
    _selectedBranch = branch;
    fetchTemplateByID(branch.templateId);
  }

  void setOverallNotes(String notes) {
    _overallNotes = notes;
    notifyListeners();
  }

  Future<void> fetchTemplateByID(String id) async {
    console("Fetching Template");
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

  // Upload photo to Firebase Storage
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

  // Upload all photos for a category
  Future<List<String>> _uploadCategoryPhotos(
    List<File> photos,
    String branchId,
    String category,
  ) async {
    final urls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < photos.length; i++) {
      final path = 'inspections/$branchId/${category}_${timestamp}_$i.jpg';
      final url = await _uploadPhoto(photos[i], path);
      urls.add(url);

      // Update progress
      _uploadProgress = ((i + 1) / photos.length) * 0.33;
      notifyListeners();
    }

    return urls;
  }

  // Submit inspection
  Future<bool> submitInspection() async {
    if (selectedTemplate == null) {
      _errorMessage = 'No template selected.';
      notifyListeners();
      return false;
    }

    // Validate that all categories have scores
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

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final Map<String, List<String>> uploadedUrls = {};

      for (int i = 0; i < selectedTemplate!.categories.length; i++) {
        final category = selectedTemplate!.categories[i];

        final files = _photos[category.categoryId] ?? [];

        // Upload photos for this category
        uploadedUrls[category.categoryId] = await _uploadCategoryPhotos(
          files,
          _selectedBranch!.id,
          category.categoryId,
        );

        // Update progress
        _uploadProgress = (i + 1) / selectedTemplate!.categories.length;
        notifyListeners();
      }

      _isUploading = false;
      notifyListeners();

      final now = DateTime.now();

      // Build inspection object dynamically
      final inspection = InspectionModel(
        id: '', // Firestore will generate
        branchId: _selectedBranch!.id,
        branchName: _selectedBranch!.name,
        inspectorId: userId,
        inspectorName: _currentUser?.name ?? '',
        scheduledTime: now,
        completedTime: now,
        status: 'completed',
        score: totalScore,
        categories: Map.fromEntries(
          selectedTemplate!.categories.map((cat) {
            final score = _scores[cat.categoryId] ?? 0;
            final notes = _notes[cat.categoryId] ?? '';
            final photos = uploadedUrls[cat.categoryId] ?? [];
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
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await _inspectionService.createInspection(inspection);

      _successMessage = 'Inspection saved successfully.';
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

  // Reset form
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

    notifyListeners();
  }
}
