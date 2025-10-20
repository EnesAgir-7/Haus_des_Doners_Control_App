import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/console.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../models/branch_model.dart';

class AdminBranchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionBranches = Collections.branches;


  Future<List<BranchModel>> getUnassignedBranches() async {
    try {
      final snapshot = await _db
          .collection(_collectionBranches)
          .where('assignedInspector', isNull: true)
          .get();
      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      console('Error getting all branches: $e');
      return [];
    }
  }
// Get inspector's assigned branches
  Future<List<BranchModel>> getInspectorBranches(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collectionBranches)
          .where('assignedInspector.id', isEqualTo: inspectorId)
          .get();

      if (snapshot.docs.isEmpty) return [];

      // Map each document to BranchModel
      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting inspector branches: $e');
      return [];
    }
  }


  // Stream all branches (admin, real-time)
  Stream<List<BranchModel>> streamAllBranches() {
    return _db
        .collection(_collectionBranches)
        .orderBy(AppConstants.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BranchModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> assignBranchToInspector({
    required String inspectorId,
    required String inspectorName,
    required String branchId,
  }) async {
    try {
      final branchDocRef = _db.collection(_collectionBranches).doc(branchId);

      await branchDocRef.update({
        'assignedInspector': {'id': inspectorId, 'name': inspectorName},
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      console(
        '✅ Branch $branchId assigned successfully to inspector $inspectorName',
      );
    } catch (e, st) {
      print("❌ Error assigning branch: $e\n$st");
      rethrow;
    }
  }

  Future<void> updateBranch(BranchModel branch) async {
    try {
      await _db.collection(_collectionBranches).doc(branch.id).update({
        'name': branch.name,
        'address': branch.address,
        'contactName': branch.contactName,
        'contactPhone': branch.contactPhone,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      console('Branch updated successfully');
    } catch (e) {
      print("Error updating branch: $e");
      rethrow;
    }
  }

  Future<void> updateBranchAssignedInspector(
    String branchId,
    Map<String, String> inspectorData,
  ) async {
    try {
      await _db.collection(_collectionBranches).doc(branchId).update({
        'assignedInspector': inspectorData,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      console('Branch assigned inspector updated successfully');
    } catch (e) {
      print("Error updating branch assigned inspector: $e");
      rethrow;
    }
  }

  Future<void> removeBranchFromInspector({required String branchId}) async {
    try {
      final branchDocRef = _db.collection(_collectionBranches).doc(branchId);

      await branchDocRef.update({
        'assignedInspector': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      console('✅ Branch $branchId unassigned successfully');
    } catch (e, st) {
      print("❌ Error unassigning branch: $e\n$st");
      rethrow;
    }
  }
}
