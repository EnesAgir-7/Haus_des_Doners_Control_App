import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/models/branch_model.dart';

import '../../../core/console.dart';

class BranchDashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get branch information
  Future<BranchModel?> getBranchInfo(String branchId) async {
    try {
      final doc = await _db.collection(Collections.branches).doc(branchId).get();

      if (!doc.exists) {
        console("No branch found with id $branchId");
        return null;
      }

      return BranchModel.fromFirestore(doc);
    } catch (e) {
      console('Error getting branch info: $e');
      return null;
    }
  }

  

  

  // Get branch notifications stream
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String branchId) {
    return _db
        .collection('notifications')
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? '',
              'message': data['message'] ?? '',
              'isRead': data['isRead'] ?? false,
              'type': data['type'] ?? 'general',
              'createdAt':
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            };
          }).toList();
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Get control reports stream
  Stream<List<Map<String, dynamic>>> getControlReportsStream(String branchId) {
    return _db
        .collection('control_reports')
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Control Report',
              'inspectorName': data['inspectorName'] ?? 'Inspector',
              'status': data['status'] ?? 'pending',
              'createdAt':
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'summary': data['summary'] ?? '',
            };
          }).toList();
        });
  }

  // Get documents stream
  Stream<List<Map<String, dynamic>>> getDocumentsStream(String branchId) {
    return _db
        .collection('documents')
        .where('targetBranches', arrayContains: branchId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Document',
              'description': data['description'] ?? '',
              'fileUrl': data['fileUrl'] ?? '',
              'fileType': data['fileType'] ?? 'pdf',
              'uploadedAt':
                  (data['uploadedAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            };
          }).toList();
        });
  }

  // Get training videos stream
  Stream<List<Map<String, dynamic>>> getTrainingVideosStream(String branchId) {
    return _db
        .collection('training_videos')
        .where('targetBranches', arrayContains: branchId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Training Video',
              'description': data['description'] ?? '',
              'videoUrl': data['videoUrl'] ?? '',
              'thumbnailUrl': data['thumbnailUrl'] ?? '',
              'duration': data['duration'] ?? 0,
              'uploadedAt':
                  (data['uploadedAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            };
          }).toList();
        });
  }

  // Submit branch update request
  Future<String> submitUpdateRequest({
    required String branchId,
    required String branchName,
    required Map<String, dynamic> requestedChanges,
    String? notes,
  }) async {
    try {
      final docRef = await _db.collection('update_requests').add({
        'branchId': branchId,
        'branchName': branchName,
        'requestedChanges': requestedChanges,
        'notes': notes,
        'status': 'pending', // pending, approved, rejected
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      console('Error submitting update request: $e');
      rethrow;
    }
  }

  // Get update requests for branch
  Stream<List<Map<String, dynamic>>> getUpdateRequestsStream(String branchId) {
    return _db
        .collection('update_requests')
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'requestedChanges': data['requestedChanges'] ?? {},
              'notes': data['notes'] ?? '',
              'status': data['status'] ?? 'pending',
              'createdAt':
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'adminNotes': data['adminNotes'],
            };
          }).toList();
        });
  }
}
