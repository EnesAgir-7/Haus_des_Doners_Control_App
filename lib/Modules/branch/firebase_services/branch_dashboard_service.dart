import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/models/branch_model.dart';

import '../../../core/console.dart';

class BranchDashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get branch information
  Future<BranchModel?> getBranchInfo(String branchId) async {
    try {
      final doc = await _db
          .collection(Collections.branches)
          .doc(branchId)
          .get();

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
}
