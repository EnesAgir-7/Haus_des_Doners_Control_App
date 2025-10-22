import 'package:cloud_firestore/cloud_firestore.dart';
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
}
