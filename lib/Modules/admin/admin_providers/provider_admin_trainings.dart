import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import '../../../models/training_video_model.dart';
import '../../../translations/locale_keys.g.dart';
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

  // Load videos for all branches (global collection)
  Future<void> loadVideos({bool refresh = false}) async {
    if (refresh) {
      _videos = [];
      _lastDocument = null;
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getTrainingVideos(
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
    await loadVideos();
  }

  Future<void> refreshVideos() async {
    await loadVideos(refresh: true);
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
        showSnakBarr(context, e.toString());
      }
      return false;
    }
  }

  Future<bool> deleteVideo(
    String videoId, {
    required BuildContext context,
  }) async {
    try {
      // delete by video id from global collection
      await _service.deleteTrainingVideo(videoId);

      _videos.removeWhere((v) => v.id == videoId);
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, LocaleKeys.video_deleted_successfully.tr());
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, '${LocaleKeys.error_deleting_video.tr()}$e');
      }
      return false;
    }
  }

  int getVideoCount() => _videos.length;

  void clear() {
    _videos = [];
    _lastDocument = null;
    _hasMore = true;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
