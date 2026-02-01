import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

class BranchNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  static const String _notificationsCollection =
      Collections.branchNotifications;

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

  /// Mark a notification as seen
  Future<void> markNotificationAsSeen(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isSeen': true, 'seenAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to mark notification as seen: $e');
    }
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

  /// Stream of unseen count for real-time updates
  Stream<int> getUnseenCountStream(String branchId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
