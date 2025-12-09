import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/branch_update_request_model.dart';

class AdminUpdateRequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collectionName = 'update_requests';

  CollectionReference get _collection => _db.collection(_collectionName);

  // Get all pending requests
  Future<List<BranchUpdateRequestModel>> getPendingRequests() async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BranchUpdateRequestModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching pending requests: $e');
    }
  }

  // Get all requests (with optional status filter)
  Future<List<BranchUpdateRequestModel>> getAllRequests({
    String? status,
  }) async {
    try {
      Query query = _collection.orderBy('requestedAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => BranchUpdateRequestModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching requests: $e');
    }
  }

  // Stream pending requests for real-time updates
  Stream<List<BranchUpdateRequestModel>> streamPendingRequests() {
    return _collection
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BranchUpdateRequestModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get single request by ID
  Future<BranchUpdateRequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _collection.doc(requestId).get();

      if (!doc.exists) return null;

      return BranchUpdateRequestModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching request: $e');
    }
  }

  // Add this method to AdminUpdateRequestService class

  // Get request statistics
  Future<Map<String, int>> getRequestStats() async {
    try {
      final pendingSnapshot = await _collection
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final approvedSnapshot = await _collection
          .where('status', isEqualTo: 'approved')
          .count()
          .get();

      final rejectedSnapshot = await _collection
          .where('status', isEqualTo: 'rejected')
          .count()
          .get();

      return {
        'pending': pendingSnapshot.count ?? 0,
        'approved': approvedSnapshot.count ?? 0,
        'rejected': rejectedSnapshot.count ?? 0,
      };
    } catch (e) {
      print('Error getting request stats: $e');
      return {'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }

  // Reject request
  Future<void> rejectRequest(
    String requestId, {
    required String adminId,
    String? adminNote,
  }) async {
    try {
      await _collection.doc(requestId).update({
        'status': 'rejected',
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        'adminNote': adminNote ?? '',
      });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Error rejecting request: $e');
    }
  }

  // Approve request (update branch + mark as approved)
  Future<void> approveRequest(
    String requestId,
    String branchId,
    Map<String, FieldChange> changes, {
    required String adminId,
    String? adminNote,
  }) async {
    try {
      // Prepare update data for branch
      final updateData = <String, dynamic>{};

      changes.forEach((key, change) {
        updateData[change.fieldKey] = change.newValue;
      });

      // Add updated timestamp
      updateData['updatedAt'] = Timestamp.now();

      // Update branch document
      await _db.collection('branches').doc(branchId).update(updateData);

      // Mark request as approved
      await _collection.doc(requestId).update({
        'status': 'approved',
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        'adminNote': adminNote ?? '',
      });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Error approving request: $e');
    }
  }

  // Get pending count
  Future<int> getPendingCount() async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting pending count: $e');
      return 0;
    }
  }

  // Get requests by branch
  Future<List<BranchUpdateRequestModel>> getRequestsByBranch(
    String branchId,
  ) async {
    try {
      final snapshot = await _collection
          .where('branchId', isEqualTo: branchId)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BranchUpdateRequestModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching branch requests: $e');
    }
  }
}
