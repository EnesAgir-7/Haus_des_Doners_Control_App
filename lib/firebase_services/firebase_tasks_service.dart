import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/console.dart';
import '../core/constants/firebase_constants.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = Collections.tasks;

  // Get tasks by inspector
  Future<List<TaskModel>> getTasksByInspector(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('assignedInspectorId', isEqualTo: inspectorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    } catch (e) {
      console('Error getting tasks by inspector: $e');
      return [];
    }
  }

  // Stream tasks by inspector (real-time)
  Stream<List<TaskModel>> streamTasksByInspector(String inspectorId) {
    return _db
        .collection(_collection)
        .where('assignedInspectorId', isEqualTo: inspectorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // Get tasks by status
  Future<List<TaskModel>> getTasksByStatus(
    String inspectorId,
    String status,
  ) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('assignedInspectorId', isEqualTo: inspectorId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    } catch (e) {
      console('Error getting tasks by status: $e');
      return [];
    }
  }

  // Get all tasks (admin)
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    } catch (e) {
      console('Error getting all tasks: $e');
      return [];
    }
  }

  // Get single task
  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final doc = await _db.collection(_collection).doc(taskId).get();
      if (!doc.exists) return null;
      return TaskModel.fromFirestore(doc);
    } catch (e) {
      console('Error getting task: $e');
      return null;
    }
  }

  // Create task
  Future<String> createTask(TaskModel task) async {
    try {
      final docRef = await _db.collection(_collection).add(task.toMap());
      return docRef.id;
    } catch (e) {
      console('Error creating task: $e');
      rethrow;
    }
  }

  // Update task
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection(_collection).doc(taskId).update(data);
    } catch (e) {
      console('Error updating task: $e');
      rethrow;
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _db.collection(_collection).doc(taskId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console('Error updating task status: $e');
      rethrow;
    }
  }

  // Add comment to task
  Future<void> addTaskComment(String taskId, TaskCommentModel comment) async {
    console("Adding comnet");
    try {
      await _db.collection(_collection).doc(taskId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
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
