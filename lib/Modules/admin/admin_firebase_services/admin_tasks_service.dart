import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:haus_des_control/core/console.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/task_model.dart';

class AdminTaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = Collections.tasks;

  // Stream tasks by inspector (real-time)
  Stream<List<TaskModel>> streamTasksByInspector(String inspectorId) {
    return _db
        .collection(_collection)
        .where(TaskFields.assignedInspectorId, isEqualTo: inspectorId)
        .orderBy(TaskFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _db.collection(_collection).doc(taskId).update({
        TaskFields.status: newStatus,
        TaskFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console('Error updating task status: $e');
      rethrow;
    }
  }

  Future<void> addTaskComment(String taskId, TaskCommentModel comment) async {
    console("Adding comnet");
    try {
      await _db.collection(_collection).doc(taskId).update({
        TaskFields.comments: FieldValue.arrayUnion([comment.toMap()]),
        TaskFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console('Error adding task comment: $e');
      rethrow;
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _db.collection(_collection).doc(taskId).delete();
    } catch (e) {
      console('Error deleting task: $e');
      rethrow;
    }
  }

  Future<bool> deleteComments(String taskId, List<String> commentIds) async {
    try {
      final taskRef = _db.collection(Collections.tasks).doc(taskId);

      // Get the current task document
      final taskDoc = await taskRef.get();

      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      final data = taskDoc.data() as Map<String, dynamic>;
      final commentsData = data[TaskFields.comments] as List<dynamic>? ?? [];

      // Convert to list of maps
      final commentsList = commentsData
          .map((c) => c as Map<String, dynamic>)
          .toList();

      // Track photos to delete from storage
      List<String> photosToDelete = [];

      // Remove comments with matching IDs and collect photos
      commentsList.removeWhere((comment) {
        final commentId = comment[TaskCommentFields.id] as String?;
        if (commentId != null && commentIds.contains(commentId)) {
          // Collect photos from this comment
          final photos = comment[TaskCommentFields.photos] as List<dynamic>?;
          if (photos != null && photos.isNotEmpty) {
            photosToDelete.addAll(photos.cast<String>());
          }
          return true; // Remove this comment
        }
        return false; // Keep this comment
      });

      // Update the task document with filtered comments
      await taskRef.update({
        TaskFields.comments: commentsList,
        TaskFields.updatedAt: FieldValue.serverTimestamp(),
      });

      // Delete photos from storage (run in background, don't wait)
      if (photosToDelete.isNotEmpty) {
        _deletePhotosFromStorage(photosToDelete);
      }

      return true;
    } catch (e) {
      print('Error deleting comments: $e');
      return false;
    }
  }

  /// Delete a single comment from a task
  Future<bool> deleteComment(String taskId, String commentId) async {
    return deleteComments(taskId, [commentId]);
  }

  /// Delete photos from Firebase Storage
  Future<void> _deletePhotosFromStorage(List<String> photoUrls) async {
    for (final photoUrl in photoUrls) {
      try {
        // Extract the storage path from the URL
        final ref = FirebaseStorage.instance.refFromURL(photoUrl);
        await ref.delete();
        print('Deleted photo: $photoUrl');
      } catch (e) {
        print('Error deleting photo $photoUrl: $e');
        // Continue with other photos even if one fails
      }
    }
  }
}
