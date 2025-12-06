import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import '../../../models/training_video_model.dart';
import '../admin_firebase_services/admin_training_service.dart';

class AdminTrainingVideosProvider extends ChangeNotifier {
  final AdminTrainingVideosService _service = AdminTrainingVideosService();

  List<TrainingVideoModel> _videos = [];
  List<TrainingVideoModel> get videos => _videos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _currentBranchId;

  Future<void> loadBranchVideos(String branchId, {bool refresh = false}) async {
    if (_currentBranchId != branchId || refresh) {
      _videos = [];
      _lastDocument = null;
      _hasMore = true;
      _currentBranchId = branchId;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getTrainingVideos(
        branchId: branchId,
        pageSize: 20,
        lastDocument: _lastDocument,
      );

      _videos.addAll(result['videos'] as List<TrainingVideoModel>);
      _lastDocument = result['lastDocument'];
      _hasMore = result['hasMore'] as bool;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreVideos() async {
    if (_currentBranchId != null) {
      await loadBranchVideos(_currentBranchId!);
    }
  }

  Future<void> refreshVideos() async {
    if (_currentBranchId != null) {
      await loadBranchVideos(_currentBranchId!, refresh: true);
    }
  }

  Future<bool> addVideo(
    TrainingVideoModel video, {
    required BuildContext context,
  }) async {
    try {
      await _service.addTrainingVideo(video);

      _videos.insert(0, video);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding video: $e')));
      }
      return false;
    }
  }

  Future<bool> deleteVideo(
    String videoId, {
    required BuildContext context,
  }) async {
    if (_currentBranchId == null) return false;

    try {
      await _service.deleteTrainingVideo(_currentBranchId!, videoId);

      _videos.removeWhere((v) => v.id == videoId);
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, 'Video deleted successfully');
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, 'Error deleting video: $e');
      }
      return false;
    }
  }

  int getVideoCount() => _videos.length;

  void clear() {
    _videos = [];
    _lastDocument = null;
    _hasMore = true;
    _currentBranchId = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
