import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/Modules/admin/admin_firebase_services/admin_user_service.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';

import '../../../common_services/notification_helper.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/task_model.dart';
import '../../../translations/locale_keys.g.dart';

class InspectorTaskService {
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

  // Create task

  // Update task status
  Future<void> updateTaskStatus({
    required String taskId,
    required String newStatus,
    required String inspectorId,
  }) async {
    final batch = _db.batch();
    final taskRef = _db.collection(_collection).doc(taskId);

    try {
      // 1️⃣ Update task document
      batch.update(taskRef, {
        TaskFields.status: newStatus,
        TaskFields.updatedAt: FieldValue.serverTimestamp(),
      });

      // 2️⃣ If task is completed → update inspector history
      if (newStatus.toLowerCase() == AppConstants.completed) {
        await AdminUserService().updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: inspectorId,
          updates: {IHF.tasksCompleted: FieldValue.increment(1)},
        );
      }

      // 3️⃣ Commit the batch
      await batch.commit();
      console('✅ Task $taskId status updated to $newStatus');

      // 4️⃣ Send notification to admins (topic)

      await NotificationHelper.instance.sendNotificationToTopic(
        topic: AppConstants.adminTopic,
        title: LocaleKeys.task_status_updated.tr(),
        body: LocaleKeys.task_status_body.tr(namedArgs: {'status': newStatus}),
        data: {
          'type': 'task_updated',
          'taskId': taskId,
          'newStatus': newStatus,
        },
      );
    } catch (e, st) {
      console('❌ Error updating task status: $e\n$st', type: DebugType.error);
      rethrow;
    }
  }

  // Add comment to task
  Future<void> addTaskComment(String taskId, TaskCommentModel comment) async {
    try {
      // Update Firestore
      await _db.collection(_collection).doc(taskId).update({
        TaskFields.comments: FieldValue.arrayUnion([comment.toMap()]),
        TaskFields.updatedAt: FieldValue.serverTimestamp(),
      });

      NotificationHelper.instance.sendNotificationToTopic(
        topic: AppConstants.adminTopic,
        title: LocaleKeys.task_comment_added_title.tr(),
        body: LocaleKeys.task_comment_added_body.tr(
          // namedArgs: {'taskId': taskId},
        ),
        data: {
          'type': 'task_comment_added',
          'taskId': taskId,
          'commentBy': comment.userId, // Using comment's userId
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      console('❌ Error adding task comment: $e');
      rethrow; // Only rethrow if the Firestore update fails
    }
  }
}
