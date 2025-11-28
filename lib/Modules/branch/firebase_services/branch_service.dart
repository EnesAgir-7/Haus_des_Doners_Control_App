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
}
