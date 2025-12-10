import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

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
}
