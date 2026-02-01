import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../translations/locale_keys.g.dart';

class AdminAnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  static const String _announcementsCollection = Collections.announcements;

  /// Create a new announcement
  ///
  /// Returns the document ID of the created announcement
  Future<String> createAnnouncement({
    required String title,
    required String description,
  }) async {
    try {
      // Create announcement document (global announcement, no branch or createdBy)
      final announcementData = {
        'title': title,
        'description': description,
        'createdBy': loggedInUser?.name ?? LocaleKeys.admin.tr(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(_announcementsCollection)
          .add(announcementData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  /// Delete an announcement
  ///
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      final docRef = _firestore
          .collection(_announcementsCollection)
          .doc(announcementId);

      // Delete announcement document
      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  /// Get all announcements across all branches (ADMIN ONLY)
  ///
  /// Returns a stream of all announcements ordered by creation date (newest first)
  /// THIS METHOD SHOULD ONLY BE USED BY ADMINS - RETURNS ALL ANNOUNCEMENTS
  Stream<QuerySnapshot> getAllAnnouncements() {
    return _firestore
        .collection(_announcementsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Mark an announcement as seen by a branch
  ///
  Future<void> markAnnouncementAsSeen({
    required String announcementId,
    required String branchId,
    required String branchName,
  }) async {
    try {
      final docRef = _firestore
          .collection(_announcementsCollection)
          .doc(announcementId);

      // We use a Map to represent AnnouncementSeenInfo in Firestore
      final seenInfo = {
        'branchId': branchId,
        'branchName': branchName,
        'seenAt':
            Timestamp.now(), // Fixed: serverTimestamp() doesn't work in arrayUnion
      };

      // To avoid duplicates if the branch opens it multiple times,
      // we could check first, but arrayUnion is simpler.
      // However, arrayUnion with serverTimestamp will always be unique.
      // Better approach: Get current seenBy and check if branch already exists.

      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final List seenBy = data['seenBy'] as List? ?? [];

      bool alreadySeen = seenBy.any((item) => item['branchId'] == branchId);

      if (!alreadySeen) {
        await docRef.update({
          'seenBy': FieldValue.arrayUnion([seenInfo]),
        });
      }
    } catch (e) {
      debugPrint('Error marking announcement as seen: $e');
    }
  }
}
