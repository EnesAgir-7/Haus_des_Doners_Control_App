import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/models/branch_model.dart';

class BranchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches a single branch document by the userId field from the `branches` collection.
  /// Returns null if no branch found.
  static Future<BranchModel?> fetchBranchByUserId(String userId) async {
    final query = await _firestore
        .collection(Collections.branches)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return BranchModel.fromFirestore(doc);
  }

  static Future<bool> hasExistingRequestForUser(String userId) async {
    final doc = await _firestore
        .collection('branch_requests')
        .doc(userId)
        .get();
    return doc.exists;
  }

  static Future<void> createBranchRequest({
    required String userId,
    required BranchModel branch,
  }) async {
    final ref = _firestore.collection('branch_requests').doc(userId);
    await ref.set({
      'userId': userId,
      'status': 'pending',
      'branchData': branch.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
