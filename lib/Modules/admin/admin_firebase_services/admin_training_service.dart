import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/training_video_model.dart';

class AdminTrainingVideosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get the videos subcollection reference for a specific branch
  CollectionReference _getVideosCollection(String branchId) {
    return _db
        .collection(Collections.trainingVideos)
        .doc(branchId)
        .collection(Collections.trainingVideos);
  }

  Future<void> addTrainingVideo(TrainingVideoModel video) async {
    try {
      final data = video.toMap();
      // Override createdAt with server timestamp for consistency
      data[TrainingVideoFields.createdAt] = FieldValue.serverTimestamp();

      await _getVideosCollection(video.branchId).doc(video.id).set(data);
    } catch (e) {
      print("Error adding training video: $e");
      rethrow;
    }
  }

  Future<void> deleteTrainingVideo(String branchId, String videoId) async {
    try {
      await _getVideosCollection(branchId).doc(videoId).delete();
    } catch (e) {
      print("Error deleting video: $e");
      rethrow;
    }
  }

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

  Future<Map<String, dynamic>> getTrainingVideos({
    required String branchId,
    int pageSize = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _getVideosCollection(branchId)
          .orderBy(TrainingVideoFields.createdAt, descending: true)
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final videos = snapshot.docs
          .map((doc) => TrainingVideoModel.fromFirestore(doc, branchId))
          .toList();

      return {
        'videos': videos,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': videos.length == pageSize,
      };
    } catch (e) {
      print("Error fetching videos: $e");
      rethrow;
    }
  }
}
