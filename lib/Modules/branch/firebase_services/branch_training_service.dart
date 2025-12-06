import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/training_video_model.dart';

class BranchTrainingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get the videos subcollection reference for a specific branch
  CollectionReference _getVideosCollection(String branchId) {
    return _db
        .collection(Collections.trainingVideos)
        .doc(branchId)
        .collection(Collections.trainingVideos);
  }

  // Stream for real-time updates (perfect for branch side)
  Stream<List<TrainingVideoModel>> getBranchTrainingVideos(String branchId) {
    return _getVideosCollection(branchId)
        .orderBy(TrainingVideoFields.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TrainingVideoModel.fromFirestore(doc, branchId))
              .toList();
        });
  }

  // One-time fetch (if you don't need real-time updates)
  Future<List<TrainingVideoModel>> fetchBranchVideos(String branchId) async {
    try {
      final snapshot = await _getVideosCollection(
        branchId,
      ).orderBy(TrainingVideoFields.createdAt, descending: true).get();

      return snapshot.docs
          .map((doc) => TrainingVideoModel.fromFirestore(doc, branchId))
          .toList();
    } catch (e) {
      print("Error fetching branch videos: $e");
      rethrow;
    }
  }

  // Get a single video
  Future<TrainingVideoModel?> getVideo(String branchId, String videoId) async {
    try {
      final doc = await _getVideosCollection(branchId).doc(videoId).get();

      if (!doc.exists) return null;

      return TrainingVideoModel.fromFirestore(doc, branchId);
    } catch (e) {
      print("Error fetching video: $e");
      rethrow;
    }
  }

  // Get video count for a branch
  Future<int> getVideoCount(String branchId) async {
    try {
      final snapshot = await _getVideosCollection(branchId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print("Error getting video count: $e");
      return 0;
    }
  }
}
