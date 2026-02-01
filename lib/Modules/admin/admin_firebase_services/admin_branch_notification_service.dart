import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../translations/locale_keys.g.dart';

class AdminBranchNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  static const String _notificationsCollection =
      Collections.branchNotifications;

  /// Create a new branch-specific notification
  ///
  /// Returns the document ID of the created notification
  Future<String> createNotification({
    required String title,
    required String description,
    required String branchId,
    required String branchName,
  }) async {
    try {
      final notificationData = {
        'title': title,
        'description': description,
        'branchId': branchId,
        'branchName': branchName,
        'createdBy': loggedInUser?.name ?? LocaleKeys.admin.tr(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isSeen': false,
        'seenAt': null,
      };

      final docRef = await _firestore
          .collection(_notificationsCollection)
          .add(notificationData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Update an existing notification
  ///
  /// Resets isSeen to false and seenAt to null when updating
  Future<void> updateNotification({
    required String notificationId,
    required String title,
    required String description,
  }) async {
    try {
      final updateData = {
        'title': title,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
        'isSeen': false, // Reset seen status when updating
        'seenAt': null, // Reset seen timestamp
      };

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Get notifications for a specific branch
  ///
  /// Returns a stream of notifications filtered by branchId
  Stream<QuerySnapshot> getNotificationsForBranch(String branchId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get all notifications across all branches (ADMIN ONLY)
  ///
  /// Returns a stream of all notifications ordered by creation date
  Stream<QuerySnapshot> getAllNotifications() {
    return _firestore
        .collection(_notificationsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get count of unseen notifications for a specific branch
  Future<int> getUnseenCount(String branchId) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('branchId', isEqualTo: branchId)
          .where('isSeen', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unseen count: $e');
    }
  }
}
