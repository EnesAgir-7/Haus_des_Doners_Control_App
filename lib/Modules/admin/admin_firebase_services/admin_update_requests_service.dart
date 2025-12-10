import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/Modules/branch/firebase_services/branch_update_request_service.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import '../../../common_services/notification_helper.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/branch_update_request_model.dart';

class AdminUpdateRequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collectionName = Collections.updateRequests;

  final String _collectionBranches = Collections.branches;

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
      print('✅ Request rejected successfully');
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Error rejecting request: $e');
    }
  }

  // Approve request (update branch + mark as approved)
  Future<void> approveRequest(
    String requestId, {
    required String branchId,
    required Map<String, FieldChange> changes,
    required String adminId,
    String? adminNote,
  }) async {
    try {
      // ---------------------------------------------------------
      // Step 1: Run transaction (update branch + update request)
      // ---------------------------------------------------------
      await _db.runTransaction((transaction) async {
        final branchRef = _db.collection(_collectionBranches).doc(branchId);
        final requestRef = _collection.doc(requestId);

        final branchSnapshot = await transaction.get(branchRef);
        if (!branchSnapshot.exists) {
          throw Exception(LocaleKeys.branchNotFound.tr());
        }

        // Prepare update map
        final Map<String, dynamic> branchUpdates = {
          'updatedAt': Timestamp.now(),
        };

        // Apply field changes
        changes.forEach((key, fieldChange) {
          branchUpdates[fieldChange.fieldKey] = _prepareValueForFirestore(
            fieldChange.newValue,
            fieldChange.fieldType,
          );
        });

        // Update branch
        transaction.update(branchRef, branchUpdates);

        // Update request
        transaction.update(requestRef, {
          'status': 'approved',
          'reviewedBy': adminId,
          'reviewedAt': Timestamp.now(),
          'adminNote': adminNote ?? 'Approved',
        });
      });

      // ---------------------------------------------------------
      // Step 2: Fetch branch after transaction to get fcmTokens
      // ---------------------------------------------------------
      final branchSnapshot = await _db
          .collection(_collectionBranches)
          .doc(branchId)
          .get();

      if (!branchSnapshot.exists) {
        throw Exception(LocaleKeys.branchNotFound.tr());
      }

      // Extract fcmTokens safely
      final data = branchSnapshot.data() as Map<String, dynamic>;
      final List<dynamic>? tokensRaw =
          data[BranchFields.fcmTokens] as List<dynamic>?;

      final List<String> fcmTokens = tokensRaw != null
          ? tokensRaw.map((t) => t.toString()).toList()
          : [];

      // If no tokens exist, you may skip or log
      if (fcmTokens.isEmpty) {
        print('⚠ No FCM tokens found for branch $branchId');
        return;
      }

      // ---------------------------------------------------------
      // Step 3: Send notification
      // ---------------------------------------------------------
      NotificationHelper.instance.sendNotificationToMultipleTokens(
        title: "Update Request Approved",
        body: "Your update request for branch has been approved.",
        fcmTokens: fcmTokens,
        data: {
          'type': 'branch_notification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Request approved, branch updated, and notification sent.');
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
}

dynamic _prepareValueForFirestore(dynamic value, String fieldType) {
  if (value == null) return null;

  switch (fieldType) {
    case DataTypes.datetime:
      if (value is DateTime) {
        return Timestamp.fromDate(value);
      } else if (value is Timestamp) {
        return value;
      }
      return value;

    case DataTypes.geopoint:
      if (value is GeoPoint) {
        return value;
      }
      return value;

    case DataTypes.list:
      if (value is List) {
        // Handle list of maps (like contact persons)
        return value.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return item;
        }).toList();
      }
      return value;

    case DataTypes.map:
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return value;

    default:
      return value;
  }
}
