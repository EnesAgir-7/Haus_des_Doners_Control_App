// lib/providers/control_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../firebase_services/firebase_inspection_service.dart';
import '../models/inspection_model.dart';
import '../models/branch_model.dart';
import '../models/user_model.dart';

/// Provider for Control (Inspection Form) screen
/// Handles creating and submitting inspections with photo uploads
class ProviderControl extends ChangeNotifier {
  final InspectionService _inspectionService = InspectionService();

  // State
  BranchModel? _selectedBranch;
  UserModel? _currentUser;

  // Category scores (1-4 rating)
  int _cleanlinessHygieneScore = 0;
  int _staffServiceScore = 0;
  int _productQualityScore = 0;

  // Photos for each category
  List<File> _cleanlinessHygienePhotos = [];
  List<File> _staffServicePhotos = [];
  List<File> _productQualityPhotos = [];

  // Notes for each category
  String _cleanlinessHygieneNotes = '';
  String _staffServiceNotes = '';
  String _productQualityNotes = '';

  // Overall notes
  String _overallNotes = '';

  // UI State
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  BranchModel? get selectedBranch => _selectedBranch;
  UserModel? get currentUser => _currentUser;

  int get cleanlinessHygieneScore => _cleanlinessHygieneScore;
  int get staffServiceScore => _staffServiceScore;
  int get productQualityScore => _productQualityScore;

  List<File> get cleanlinessHygienePhotos => _cleanlinessHygienePhotos;
  List<File> get staffServicePhotos => _staffServicePhotos;
  List<File> get productQualityPhotos => _productQualityPhotos;

  String get cleanlinessHygieneNotes => _cleanlinessHygieneNotes;
  String get staffServiceNotes => _staffServiceNotes;
  String get productQualityNotes => _productQualityNotes;
  String get overallNotes => _overallNotes;

  bool get isSubmitting => _isSubmitting;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Computed: Overall score (average of categories)
  double get totalScore {
    if (_cleanlinessHygieneScore == 0 &&
        _staffServiceScore == 0 &&
        _productQualityScore == 0) {
      return 0.0;
    }
    final total =
        _cleanlinessHygieneScore + _staffServiceScore + _productQualityScore;
    final count =
        (_cleanlinessHygieneScore > 0 ? 1 : 0) +
        (_staffServiceScore > 0 ? 1 : 0) +
        (_productQualityScore > 0 ? 1 : 0);

    // Convert 1-4 scale to 0-10 scale
    return count > 0 ? (total / count) * 2.5 : 0.0;
  }

  bool get isFormValid {
    return _selectedBranch != null &&
        _cleanlinessHygieneScore > 0 &&
        _staffServiceScore > 0 &&
        _productQualityScore > 0;
  }

  // Initialize with branch and user
  void initialize(BranchModel branch, UserModel user) {
    _selectedBranch = branch;
    _currentUser = user;
    resetForm();
  }

  // Set category scores
  void setCleanlinessHygieneScore(int score) {
    _cleanlinessHygieneScore = score;
    notifyListeners();
  }

  void setStaffServiceScore(int score) {
    _staffServiceScore = score;
    notifyListeners();
  }

  void setProductQualityScore(int score) {
    _productQualityScore = score;
    notifyListeners();
  }

  // Add photos
  void addCleanlinessHygienePhoto(File photo) {
    if (_cleanlinessHygienePhotos.length < 4) {
      _cleanlinessHygienePhotos.add(photo);
      notifyListeners();
    }
  }

  void removeCleanlinessHygienePhoto(int index) {
    _cleanlinessHygienePhotos.removeAt(index);
    notifyListeners();
  }

  void addStaffServicePhoto(File photo) {
    if (_staffServicePhotos.length < 4) {
      _staffServicePhotos.add(photo);
      notifyListeners();
    }
  }

  void removeStaffServicePhoto(int index) {
    _staffServicePhotos.removeAt(index);
    notifyListeners();
  }

  void addProductQualityPhoto(File photo) {
    if (_productQualityPhotos.length < 4) {
      _productQualityPhotos.add(photo);
      notifyListeners();
    }
  }

  void removeProductQualityPhoto(int index) {
    _productQualityPhotos.removeAt(index);
    notifyListeners();
  }

  // Set notes
  void setCleanlinessHygieneNotes(String notes) {
    _cleanlinessHygieneNotes = notes;
    notifyListeners();
  }

  void setStaffServiceNotes(String notes) {
    _staffServiceNotes = notes;
    notifyListeners();
  }

  void setProductQualityNotes(String notes) {
    _productQualityNotes = notes;
    notifyListeners();
  }

  void setOverallNotes(String notes) {
    _overallNotes = notes;
    notifyListeners();
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
      print('Error uploading photo: $e');
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
    if (!isFormValid) {
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

      // Upload photos for each category
      final cleanlinessUrls = await _uploadCategoryPhotos(
        _cleanlinessHygienePhotos,
        _selectedBranch!.id,
        'cleanliness',
      );
      _uploadProgress = 0.33;
      notifyListeners();

      final staffUrls = await _uploadCategoryPhotos(
        _staffServicePhotos,
        _selectedBranch!.id,
        'staff',
      );
      _uploadProgress = 0.66;
      notifyListeners();

      final productUrls = await _uploadCategoryPhotos(
        _productQualityPhotos,
        _selectedBranch!.id,
        'product',
      );
      _uploadProgress = 1.0;
      notifyListeners();

      _isUploading = false;
      notifyListeners();

      // Create inspection model
      final now = DateTime.now();
      final inspection = InspectionModel(
        id: '', // Will be set by Firestore
        branchId: _selectedBranch!.id,
        branchName: _selectedBranch!.name,
        inspectorId: userId,
        inspectorName: _currentUser?.name ?? '',
        scheduledTime: now,
        completedTime: now,
        status: 'completed',
        score: totalScore,
        cleanlinessHygiene: InspectionCategoryModel(
          score: _cleanlinessHygieneScore,
          photos: cleanlinessUrls,
          notes: _cleanlinessHygieneNotes,
        ),
        staffService: InspectionCategoryModel(
          score: _staffServiceScore,
          photos: staffUrls,
          notes: _staffServiceNotes,
        ),
        productQuality: InspectionCategoryModel(
          score: _productQualityScore,
          photos: productUrls,
          notes: _productQualityNotes,
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

      // Reset form after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      resetForm();

      return true;
    } catch (e) {
      _errorMessage =
          'An error occurred while saving inspection: ${e.toString()}';
      _isSubmitting = false;
      _isUploading = false;
      notifyListeners();
      print(_errorMessage);
      return false;
    }
  }

  // Reset form
  void resetForm() {
    _cleanlinessHygieneScore = 0;
    _staffServiceScore = 0;
    _productQualityScore = 0;

    _cleanlinessHygienePhotos.clear();
    _staffServicePhotos.clear();
    _productQualityPhotos.clear();

    _cleanlinessHygieneNotes = '';
    _staffServiceNotes = '';
    _productQualityNotes = '';
    _overallNotes = '';

    _uploadProgress = 0.0;
    _errorMessage = null;
    _successMessage = null;

    _isSubmitting = false;
    _isUploading = false;

    notifyListeners();
  }
}
