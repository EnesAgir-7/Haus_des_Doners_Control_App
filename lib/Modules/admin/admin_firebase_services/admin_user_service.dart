import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/inspector_history_model.dart';
import '../../../models/user_model.dart';

class AdminUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream all inspectors

  Stream<List<UserModel>> streamAllInspectors() {
    try {
      return _db.collection(Collections.inspectors).snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error streaming all inspectors: $e');
      // Return an empty stream in case of error
      return Stream.value([]);
    }
  }

  Future<InspectorHistoryModel?> getInspectorStats(String userId) async {
    try {
      final docRef = _db.collection(Collections.inspectorStats).doc(userId);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final stats = InspectorHistoryModel.fromFirestore(docSnapshot);
        return stats;
      } else {
        print('⚠️ Inspector stats document not found for ID: $userId');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching inspector stats for ID $userId: $e');
      rethrow;
    }
  }

  // Update inspector
  Future<void> updateInspector(String userId, Map<String, dynamic> data) async {
    try {
      data[UserFields.updatedAt] = FieldValue.serverTimestamp();
      await _db.collection(Collections.inspectors).doc(userId).update(data);
    } catch (e) {
      print('Error updating inspector: $e');
      rethrow;
    }
  }

  // Create user (inspector or admin)
  Future<void> createUser(String userId, UserModel user) async {
    try {
      String collectionName;
      switch (user.role.toLowerCase()) {
        case AppConstants.inspector:
          collectionName = Collections.inspectors;
          break;
        case AppConstants.admin:
          collectionName = Collections.admins;
          break;
        default:
          throw Exception('Invalid user role: ${user.role}');
      }

      await _db.collection(collectionName).doc(userId).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }



/// 🔹 Updates any field(s) in the inspector history using a batch.
  /// Pass a map of values to update, e.g. {IHF.totalInspections: 5}.
  /// If the doc doesn't exist, it will create a new one with default values plus the provided updates.
  Future<void> updateInspectorHistoryBatch({
    required WriteBatch batch,
    required String inspectorId,
    required Map<String, dynamic> updates,
  }) async {
    final inspectorRef = FirebaseFirestore.instance
        .collection(Collections.inspectorStats)
        .doc(inspectorId);

    final inspectorDoc = await inspectorRef.get();

    if (inspectorDoc.exists) {
      batch.update(inspectorRef, {
        ...updates,
        IHF.lastUpdated: FieldValue.serverTimestamp(),
      });
    } else {
      batch.set(inspectorRef, {
        IHF.inspectorId: inspectorId,
        IHF.totalInspections: "0",
        IHF.avgScore: "0.0",
        IHF.tasksTotal: "0",
        IHF.tasksCompleted: "0",
        IHF.recentScores: [],
        IHF.vehicleIds: [],
        IHF.branchesIds: [],
        IHF.lastUpdated: FieldValue.serverTimestamp(),
        ...updates, // apply the provided updates
      });
    }
  }


}
