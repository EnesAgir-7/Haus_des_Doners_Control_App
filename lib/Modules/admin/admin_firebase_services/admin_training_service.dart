import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/training_video_model.dart';

class AdminTrainingVideosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Global collection for training videos (flat structure)
  CollectionReference get _globalVideos =>
      _db.collection(Collections.trainingVideos);

  Future<void> addTrainingVideo(TrainingVideoModel video) async {
    try {
      final data = video.toMap();
      data[TrainingVideoFields.createdAt] = FieldValue.serverTimestamp();
      await _globalVideos.doc(video.id).set(data);
    } catch (e) {
      print("Error adding training video: $e");
      rethrow;
    }
  }

  Future<void> deleteTrainingVideo(String videoId) async {
    try {
      await _globalVideos.doc(videoId).delete();
      print("Training video deleted: $videoId");
    } catch (e) {
      print("Error deleting training video: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTrainingVideos({
    String? branchId,
    int pageSize = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _globalVideos
          .orderBy(TrainingVideoFields.createdAt, descending: true)
          .limit(pageSize);

      if (branchId != null && branchId.isNotEmpty) {
        query = _globalVideos
            .where(TrainingVideoFields.branchId, isEqualTo: branchId)
            .orderBy(TrainingVideoFields.createdAt, descending: true)
            .limit(pageSize);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final videos = snapshot.docs
          .map((doc) => TrainingVideoModel.fromFirestore(doc))
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
