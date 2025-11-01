import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:haus_des_control/Modules/admin/admin_firebase_services/admin_user_service.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/task_model.dart';

class AdminTaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = Collections.tasks;
  final AdminUserService adminUserService = AdminUserService();

  Stream<List<TaskModel>> streamAllTasks(String inspectorId) {
    return _db
        .collection(_collection)
        .orderBy(TaskFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
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
  /// Delete task and update inspector history
  Future<void> deleteTask(String taskId) async {
    // Get task to know which inspector to update
    final task = await getTaskById(taskId);
    if (task == null) {
      throw Exception('Task not found');
    }

    final batch = _db.batch();

    // Delete task document
    final docRef = _db.collection(Collections.tasks).doc(taskId);

    batch.delete(docRef);

    // Only update history if task was NOT completed
    // Completed tasks should remain in history even if deleted
    if (task.status != AppConstants.completed) {
      await adminUserService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: task.assignedInspectorId,
        updates: {IHF.tasksTotal: FieldValue.increment(-1)},
      );
    }

    // Commit batch
    await batch.commit();
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

  // Get tasks by inspector
  Future<List<TaskModel>> getTasksByInspector(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where(TaskFields.assignedInspectorId, isEqualTo: inspectorId)
          .orderBy(TaskFields.createdAt, descending: true)
          .get();

      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    } catch (e) {
      console('Error getting tasks by inspector: $e');
      return [];
    }
  }

  // Get single task
  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final doc = await _db.collection(Collections.tasks).doc(taskId).get();

      if (!doc.exists) return null;

      return TaskModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting task: $e');
      return null;
    }
  }

  // Create task
  Future<void> createTask(TaskModel task) async {
    final batch = _db.batch();

    final docRef = _db.collection(Collections.tasks).doc();

    final taskData = task.copyWith(id: docRef.id).toMap();
    batch.set(docRef, taskData);

    await adminUserService.updateInspectorHistoryBatch(
      batch: batch,
      inspectorId: task.assignedInspectorId,
      updates: {IHF.tasksTotal: FieldValue.increment(1)},
    );

    // Commit batch
    await batch.commit();
  }

  // Update task
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    // Get current task state
    final currentTask = await getTaskById(taskId);
    if (currentTask == null) {
      throw Exception('Task not found');
    }

    final batch = _db.batch();

    // Update task document
    final docRef = _db.collection(Collections.tasks).doc(taskId);

    final updateData = {...data, TaskFields.updatedAt: Timestamp.now()};

    batch.update(docRef, updateData);

    // Check if inspector was changed
    final newInspectorId = data[TaskFields.assignedInspectorId] as String?;
    final inspectorChanged =
        newInspectorId != null &&
        newInspectorId != currentTask.assignedInspectorId;

    if (inspectorChanged) {
      // Decrement from old inspector
      await adminUserService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: currentTask.assignedInspectorId,
        updates: {
          IHF.tasksTotal: FieldValue.increment(-1),
          // If task was completed, also decrement completed count
          if (currentTask.status == AppConstants.completed)
            IHF.tasksCompleted: FieldValue.increment(-1),
        },
      );

      // Increment for new inspector
      await adminUserService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: newInspectorId,
        updates: {
          IHF.tasksTotal: FieldValue.increment(1),
          // If task is completed, also increment completed count
          if (currentTask.status == AppConstants.completed)
            IHF.tasksCompleted: FieldValue.increment(1),
        },
      );
    }

    // Check if status changed to/from completed (only if inspector wasn't changed)
    final newStatus = data[TaskFields.status] as String?;
    final statusChanged = newStatus != null && newStatus != currentTask.status;

    if (statusChanged && !inspectorChanged) {
      if (newStatus == AppConstants.completed &&
          currentTask.status != AppConstants.completed) {
        // Task was just completed
        await adminUserService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: currentTask.assignedInspectorId,
          updates: {IHF.tasksCompleted: FieldValue.increment(1)},
        );
      } else if (newStatus != AppConstants.completed &&
          currentTask.status == AppConstants.completed) {
        // Task was un-completed
        await adminUserService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: currentTask.assignedInspectorId,
          updates: {IHF.tasksCompleted: FieldValue.increment(-1)},
        );
      }
    }

    // Commit batch
    await batch.commit();
  }
}
