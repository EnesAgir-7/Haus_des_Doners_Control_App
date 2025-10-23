import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/Modules/admin/admin_firebase_services/admin_user_service.dart';
import 'package:haus_des_control/core/console.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../models/branch_model.dart';

class AdminBranchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionBranches = Collections.branches;
  final AdminUserService _userService = AdminUserService();

  // Get all unassigned branches
  Future<List<BranchModel>> getUnassignedBranches() async {
    try {
      final snapshot = await _db
          .collection(_collectionBranches)
          .where(BranchFields.assignedInspector, isNull: true)
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
          .where('${BranchFields.assignedInspectorId}', isEqualTo: inspectorId)
          .get();

      if (snapshot.docs.isEmpty) return [];

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
        .orderBy(BranchFields.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BranchModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateBranch(BranchModel branch) async {
    try {
      await _db.collection(_collectionBranches).doc(branch.id).update({
        BranchFields.name: branch.name,
        BranchFields.address: branch.address,
        BranchFields.contactName: branch.contactName,
        BranchFields.contactPhone: branch.contactPhone,
        BranchFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      });
      console('Branch updated successfully');
    } catch (e) {
      print("Error updating branch: $e");
      rethrow;
    }
  }

  Future<void> updateBranchTemplate({
    required String branchId,
    required String templateId,
    required String templateName,
  }) async {
    try {
      // You should have defined BranchFields as constants for safety
      await _db.collection(_collectionBranches).doc(branchId).update({
        BranchFields.templateId: templateId,
        BranchFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      });
      console(
        'Branch $branchId template updated to: $templateName ($templateId)',
      );
    } catch (e) {
      print("Error updating branch template: $e");
      rethrow;
    }
  }

  Future<void> updateBranchAssignedInspector(
    String branchId,
    Map<String, String> inspectorData,
  ) async {
    try {
      await _db.collection(_collectionBranches).doc(branchId).update({
        BranchFields.assignedInspector: inspectorData,
        BranchFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      });
      console('Branch assigned inspector updated successfully');
    } catch (e) {
      print("Error updating branch assigned inspector: $e");
      rethrow;
    }
  }

  Future<void> removeBranchFromInspector({
    required String inspectorId,
    required String branchId,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final branchRef = FirebaseFirestore.instance
        .collection(_collectionBranches)
        .doc(branchId);

    try {
      // 1️⃣ Unassign branch document
      batch.update(branchRef, {
        BranchFields.assignedInspector: null,
        BranchFields.updatedAt: Timestamp.now(),
      });

      // 2️⃣ Update inspector history
      await _userService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: inspectorId,
        updates: {
          IHF.branchesIds: FieldValue.arrayRemove([branchId]),
        },
      );

      // 3️⃣ Commit batch
      await batch.commit();

      console('✅ Branch $branchId unassigned successfully and history updated');
    } catch (e, st) {
      print("❌ Error unassigning branch: $e\n$st");
      rethrow;
    }
  }

  Future<void> assignBranchToInspector({
    required String inspectorId,
    required String inspectorName,
    required String branchId,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final branchRef = FirebaseFirestore.instance
        .collection(_collectionBranches)
        .doc(branchId);

    try {
      // 1️⃣ Update branch document
      batch.update(branchRef, {
        BranchFields.assignedInspector: {
          InspectorFields.id: inspectorId,
          InspectorFields.name: inspectorName,
        },
        BranchFields.updatedAt: Timestamp.now(),
      });

      // 2️⃣ Update inspector history
      await _userService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: inspectorId,
        updates: {
          IHF.branchesIds: FieldValue.arrayUnion([branchId]),
        },
      );

      // 3️⃣ Commit batch
      await batch.commit();

      console('✅ Branch $branchId assigned successfully to $inspectorName');
    } catch (e, st) {
      print("❌ Error assigning branch: $e\n$st");
      rethrow;
    }
  }
}
