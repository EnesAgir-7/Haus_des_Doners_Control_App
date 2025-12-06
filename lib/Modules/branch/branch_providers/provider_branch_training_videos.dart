import 'package:flutter/material.dart';
import '../../../models/training_video_model.dart';
import '../firebase_services/branch_training_service.dart';

class BranchTrainingProvider extends ChangeNotifier {
  final BranchTrainingService _service = BranchTrainingService();

  List<TrainingVideoModel> _videos = [];
  List<TrainingVideoModel> get videos => _videos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _currentBranchId;

  // Load videos for the branch user
  Future<void> loadMyVideos(String branchId) async {
    _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _videos = await _service.fetchBranchVideos(branchId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Use stream for real-time updates (recommended)
  Stream<List<TrainingVideoModel>> watchMyVideos(String branchId) {
    return _service.getBranchTrainingVideos(branchId);
  }

  // Refresh videos
  Future<void> refreshVideos() async {
    if (_currentBranchId != null) {
      await loadMyVideos(_currentBranchId!);
    }
  }

  int getVideoCount() => _videos.length;

  void clear() {
    _videos = [];
    _currentBranchId = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
