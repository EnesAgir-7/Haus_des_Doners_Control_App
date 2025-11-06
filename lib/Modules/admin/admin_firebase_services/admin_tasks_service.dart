import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_firebase_services/admin_user_service.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';

import '../../../common_services/notification_helper.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../helpers/app_helpers.dart';
import '../../../models/task_model.dart';
import '../../../translations/locale_keys.g.dart';

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

  Future<void> addTaskComment(
    String taskId,
    TaskCommentModel comment,
    String inspectorId,
  ) async {
    console("Adding comment");
    try {
      // Update Firestore
      await _db.collection(_collection).doc(taskId).update({
        TaskFields.comments: FieldValue.arrayUnion([comment.toMap()]),
        TaskFields.updatedAt: FieldValue.serverTimestamp(),
      });

      // ✅ Send notification to admins (wrapped in try-catch so it won't block)
      try {
        await FCMHelper.instance.sendNotificationToTopic(
          topic: AppConstants.adminTopic,
          title: LocaleKeys.task_comment_added_title.tr(),
          body: LocaleKeys.task_comment_added_body.tr(
            namedArgs: {'taskId': taskId},
          ),
          data: {
            'type': 'task_comment_added',
            'taskId': taskId,
            'commentBy': inspectorId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (notificationError) {
        console('⚠️ Failed to send comment notification: $notificationError');
        // Do NOT rethrow; method continues successfully
      }
    } catch (e) {
      console('❌ Error adding task comment: $e');
      rethrow; // Only rethrow if the Firestore update fails
    }
  }

  // Delete task
  /// Delete task and update inspector history
  Future<void> deleteTask(String taskId, BuildContext context) async {
    final task = await getTaskById(taskId);
    if (task == null) {
      throw Exception(LocaleKeys.no_tasks_found.tr());
    }

    final batch = _db.batch();

    // Delete task document
    final docRef = _db.collection(Collections.tasks).doc(taskId);
    batch.delete(docRef);

    // Only update history if task was NOT completed
    if (task.status != AppConstants.completed) {
      await adminUserService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: task.assignedInspectorId,
        updates: {IHF.tasksTotal: FieldValue.increment(-1)},
      );
    }

    // Commit batch
    await batch.commit();
    console('✅ Task $taskId deleted successfully');

    // ✅ Notifications
    try {
      // ✅ 1. Notify inspector
      final inspectorTokens = getInspectorTokens(
        task.assignedInspectorId,
        context,
      );
      if (inspectorTokens.isNotEmpty) {
        console('📤 Notifying inspector about deleted task');

        await FCMHelper.instance.sendNotificationToMultipleTokens(
          fcmTokens: inspectorTokens,
          title: LocaleKeys.task_deleted_title.tr(),
          body: LocaleKeys.task_deleted_body.tr(
            namedArgs: {'taskTitle': task.title},
          ),
          data: {
            'type': 'task_deleted',
            'taskId': taskId,
            'taskTitle': task.title,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      console('⚠️ Notification error (deleteTask): $e');
    }
  }

  Future<bool> deleteComments(String taskId, List<String> commentIds) async {
    try {
      final taskRef = _db.collection(Collections.tasks).doc(taskId);

      // Get the current task document
      final taskDoc = await taskRef.get();

      if (!taskDoc.exists) {
        throw Exception(LocaleKeys.no_tasks_found.tr());
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
  Future<void> createTask(TaskModel task, BuildContext context) async {
    final batch = _db.batch();

    try {
      final docRef = _db.collection(Collections.tasks).doc();

      final taskData = task.copyWith(id: docRef.id).toMap();
      batch.set(docRef, taskData);

      // Update inspector's total tasks
      await adminUserService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: task.assignedInspectorId,
        updates: {IHF.tasksTotal: FieldValue.increment(1)},
      );

      // Commit batch
      await batch.commit();
      console('✅ Task created successfully: ${docRef.id}');

      // ✅ Send notification to assigned inspector
      try {
        final inspectorTokens = getInspectorTokens(
          task.assignedInspectorId,
          context,
        );

        if (inspectorTokens.isNotEmpty) {
          console(
            '📤 Sending task notification to ${inspectorTokens.length} device(s)',
          );

          await FCMHelper.instance.sendNotificationToMultipleTokens(
            fcmTokens: inspectorTokens,
            title: LocaleKeys.task_assigned_title.tr(),
            body: LocaleKeys.task_assigned_body.tr(
              namedArgs: {'taskTitle': task.title},
            ),
            data: {
              'type': 'task_assigned',
              'taskId': docRef.id,
              'taskTitle': task.title,
              'taskDescription': task.description,
              'taskPriority': task.priority,
              'dueDate': task.dueDate?.toIso8601String() ?? '',
              'inspectorId': task.assignedInspectorId,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        } else {
          console(
            '⚠️ No FCM tokens found for inspector ${task.assignedInspectorId}',
          );
        }
      } catch (notificationError) {
        console('⚠️ Task notification error: $notificationError');
      }
    } catch (e, st) {
      console('❌ Error creating task: $e\n$st', type: DebugType.error);
      rethrow;
    }
  }

  // Update task
  Future<void> updateTask(
    String taskId,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    // Get current task state
    final currentTask = await getTaskById(taskId);
    if (currentTask == null) {
      throw Exception(LocaleKeys.no_tasks_found.tr());
    }

    final batch = _db.batch();

    // Update task document
    final docRef = _db.collection(Collections.tasks).doc(taskId);
    final updateData = {...data, TaskFields.updatedAt: Timestamp.now()};
    batch.update(docRef, updateData);

    // Check if inspector was changed
    final String? newInspectorId =
        data[TaskFields.assignedInspectorId] as String?;
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
          if (currentTask.status == AppConstants.completed)
            IHF.tasksCompleted: FieldValue.increment(1),
        },
      );
    }

    // Check if status changed
    final newStatus = data[TaskFields.status] as String?;
    final statusChanged = newStatus != null && newStatus != currentTask.status;

    if (statusChanged && !inspectorChanged) {
      if (newStatus == AppConstants.completed &&
          currentTask.status != AppConstants.completed) {
        await adminUserService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: currentTask.assignedInspectorId,
          updates: {IHF.tasksCompleted: FieldValue.increment(1)},
        );
      } else if (newStatus != AppConstants.completed &&
          currentTask.status == AppConstants.completed) {
        await adminUserService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: currentTask.assignedInspectorId,
          updates: {IHF.tasksCompleted: FieldValue.increment(-1)},
        );
      }
    }

    // Commit batch
    await batch.commit();
    console('✅ Task $taskId updated successfully');

    // ✅ NOTIFICATIONS
    try {
      // Helper to get inspector FCM tokens from provider

      // ✅ Scenario 1: Inspector was reassigned
      if (inspectorChanged) {
        // Notify OLD inspector (task unassigned)
        final oldInspectorTokens = getInspectorTokens(
          currentTask.assignedInspectorId,
          context,
        );
        if (oldInspectorTokens.isNotEmpty) {
          console('📤 Notifying old inspector about task removal');
          await FCMHelper.instance.sendNotificationToMultipleTokens(
            fcmTokens: oldInspectorTokens,
            title: LocaleKeys.task_unassigned_title.tr(),
            body: LocaleKeys.task_unassigned_body.tr(
              namedArgs: {'taskTitle': currentTask.title},
            ),
            data: {
              'type': 'task_unassigned',
              'taskId': taskId,
              'taskTitle': currentTask.title,
              'reason': 'reassigned',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }

        // Notify NEW inspector (task assigned)
        final newInspectorTokens = getInspectorTokens(newInspectorId, context);
        if (newInspectorTokens.isNotEmpty) {
          console('📤 Notifying new inspector about task assignment');
          await FCMHelper.instance.sendNotificationToMultipleTokens(
            fcmTokens: newInspectorTokens,
            title: LocaleKeys.task_assigned_title.tr(),
            body: LocaleKeys.task_assigned_body.tr(
              namedArgs: {'taskTitle': currentTask.title},
            ),
            data: {
              'type': 'task_assigned',
              'taskId': taskId,
              'taskTitle': currentTask.title,
              'taskDescription': currentTask.description,
              'taskPriority': currentTask.priority,
              'dueDate': currentTask.dueDate?.toIso8601String() ?? '',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      }
      // ✅ Scenario 2: Task updated (same inspector)
      else {
        final inspectorTokens = getInspectorTokens(
          currentTask.assignedInspectorId,
          context,
        );
        if (inspectorTokens.isNotEmpty) {
          String notificationTitle;
          String notificationBody;
          String notificationType;

          if (statusChanged && newStatus == AppConstants.completed) {
            console('⏭️ Skipping notification - task completed by inspector');
            return;
          } else if (statusChanged) {
            notificationTitle = LocaleKeys.task_status_changed_title.tr();
            notificationBody = LocaleKeys.task_status_changed_body.tr(
              namedArgs: {
                'taskTitle': currentTask.title,
                'newStatus': newStatus,
              },
            );
            notificationType = 'task_status_changed';
          } else {
            notificationTitle = LocaleKeys.task_updated_title.tr();
            notificationBody = LocaleKeys.task_updated_body.tr(
              namedArgs: {'taskTitle': currentTask.title},
            );
            notificationType = 'task_updated';
          }

          console('📤 Notifying inspector about task update');

          await FCMHelper.instance.sendNotificationToMultipleTokens(
            fcmTokens: inspectorTokens,
            title: notificationTitle,
            body: notificationBody,
            data: {
              'type': notificationType,
              'taskId': taskId,
              'taskTitle': currentTask.title,
              'updatedFields': data.keys.toList(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      }
    } catch (notificationError) {
      console('⚠️ Notification error: $notificationError');
    }
  }
}
