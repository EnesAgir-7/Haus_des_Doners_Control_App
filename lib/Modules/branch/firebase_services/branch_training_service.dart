import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/training_video_model.dart';

class BranchTrainingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _globalVideos =>
      _db.collection(Collections.trainingVideos);

  // Stream for real-time updates for a specific branch (global collection filtered by branchId)
  Stream<List<TrainingVideoModel>> getBranchTrainingVideos(String branchId) {
    return _globalVideos
        .where(TrainingVideoFields.branchId, isEqualTo: branchId)
        .orderBy(TrainingVideoFields.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TrainingVideoModel.fromFirestore(doc))
              .toList();
        });
  }

  // One-time fetch (if you don't need real-time updates)
  Future<List<TrainingVideoModel>> fetchBranchVideos(String branchId) async {
    try {
      final snapshot = await _globalVideos
          .where(TrainingVideoFields.branchId, isEqualTo: branchId)
          .orderBy(TrainingVideoFields.createdAt, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TrainingVideoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching branch videos: $e");
      rethrow;
    }
  }

  // Get a single video by id and ensure it belongs to the branch
  Future<TrainingVideoModel?> getVideo(String branchId, String videoId) async {
    try {
      final doc = await _globalVideos.doc(videoId).get();

      if (!doc.exists) return null;

      final model = TrainingVideoModel.fromFirestore(doc);
      if (model.branchId != branchId) return null;

      return model;
    } catch (e) {
      print("Error fetching video: $e");
      rethrow;
    }
  }

  // Get video count for a branch
  Future<int> getVideoCount(String branchId) async {
    try {
      final snapshot = await _globalVideos
          .where(TrainingVideoFields.branchId, isEqualTo: branchId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print("Error getting video count: $e");
      return 0;
    }
  }

  // Stream all videos (global collection) - used when videos are not branch-specific
  Stream<List<TrainingVideoModel>> getAllTrainingVideos() {
    return _globalVideos
        .orderBy(TrainingVideoFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrainingVideoModel.fromFirestore(doc))
              .toList(),
        );
  }

  // One-time fetch for all videos
  Future<List<TrainingVideoModel>> fetchAllVideos() async {
    try {
      final snapshot = await _globalVideos
          .orderBy(TrainingVideoFields.createdAt, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TrainingVideoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching all videos: $e");
      rethrow;
    }
  }
}
