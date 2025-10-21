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
        print('Firebase stream update: ${snapshot.docs.length} inspectors');
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
      data['updatedAt'] = FieldValue.serverTimestamp();
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


}
