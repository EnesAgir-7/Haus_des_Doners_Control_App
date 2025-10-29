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
        BranchFields.region: branch.region,
        BranchFields.gps: branch.gps,
        BranchFields.updatedAt: Timestamp.now(),
      });
      console('✅ Branch updated successfully');
    } catch (e) {
      print("❌ Error updating branch: $e");
      rethrow;
    }
  }

  /// Add a new branch
  Future<void> addBranch(BranchModel branch) async {
    try {
      // Use branch.id as doc id, or generate new one if empty
      final docRef = branch.id.isNotEmpty
          ? _db.collection(_collectionBranches).doc(branch.id)
          : _db.collection(_collectionBranches).doc();

      await docRef.set({
        BranchFields.id: docRef.id,
        BranchFields.name: branch.name,
        BranchFields.address: branch.address,
        BranchFields.templateId: branch.templateId,
        BranchFields.templateName: branch.templateName,
        BranchFields.region: branch.region,
        BranchFields.gps: branch.gps,
        BranchFields.contactName: branch.contactName,
        BranchFields.contactPhone: branch.contactPhone,
        BranchFields.stop: branch.stop != null ? branch.stop!.toMap() : null,
        BranchFields.assignedInspector: branch.assignedInspector != null
            ? branch.assignedInspector!.toJson()
            : null,
        BranchFields.lastInspectionDate: branch.lastInspectionDate != null
            ? Timestamp.fromDate(branch.lastInspectionDate!)
            : null,
        BranchFields.lastInspectionScore: branch.lastInspectionScore,
        BranchFields.totalInspections: branch.totalInspections,
        BranchFields.averageScore: branch.averageScore,
        BranchFields.status: branch.status,
        BranchFields.last12MonthsScores: branch.last12MonthsScores ?? [],
        BranchFields.createdAt: Timestamp.now(),
        BranchFields.updatedAt: Timestamp.now(),
      });

      print('Branch added successfully with id: ${docRef.id}');
    } catch (e) {
      print('Error adding branch: $e');
      rethrow;
    }
  }

  Stream<List<BranchModel>> streamBranchesByIds(List<String> branchIds) {
    if (branchIds.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection(Collections.branches)
        .where(FieldPath.documentId, whereIn: branchIds)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BranchModel.fromFirestore(doc))
              .toList(),
        );
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
        BranchFields.templateName: templateName,
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

  Future<void> removeBranchFromInspector({
    required String inspectorId,
    required String branchId,
  }) async {
    final batch = _db.batch();
    final branchRef = _db.collection(_collectionBranches).doc(branchId);

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

  Future<void> deleteBranch({
    required String branchId,
    required String? inspectorId,
  }) async {
    final batch = _db.batch();
    final branchRef = _db.collection(_collectionBranches).doc(branchId);

    try {
      // 1️⃣ Delete the branch document
      batch.delete(branchRef);

      // 2️⃣ If an inspector was assigned, update their history
      if (inspectorId != null && inspectorId.isNotEmpty) {
        await _userService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: inspectorId,
          updates: {
            IHF.branchesIds: FieldValue.arrayRemove([branchId]),
          },
        );
      }

      // 3️⃣ Commit batch
      await batch.commit();

      console('✅ Branch $branchId deleted successfully');
    } catch (e, st) {
      print("❌ Error deleting branch $branchId: $e\n$st");
      rethrow;
    }
  }

  Future<void> assignBranchToInspector({
    required String inspectorId,
    required String inspectorName,
    required String branchId,
    String? oldInspectorId,
  }) async {
    final batch = _db.batch();
    final branchRef = _db.collection(_collectionBranches).doc(branchId);

    try {
      // 1️⃣ Update the branch document
      batch.update(branchRef, {
        BranchFields.assignedInspector: {
          InspectorFields.id: inspectorId,
          InspectorFields.name: inspectorName,
        },
        BranchFields.updatedAt: Timestamp.now(),
      });

      // 2️⃣ Only remove from old inspector if it's DIFFERENT
      if (oldInspectorId != null &&
          oldInspectorId.isNotEmpty &&
          oldInspectorId != inspectorId) {
        await _userService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: oldInspectorId,
          updates: {
            IHF.branchesIds: FieldValue.arrayRemove([branchId]),
          },
        );
      }

      await _userService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: inspectorId,
        updates: {
          IHF.branchesIds: FieldValue.arrayUnion([branchId]),
        },
      );

      // 4️⃣ Commit the batch
      await batch.commit();

      console('✅ Branch $branchId assigned successfully to $inspectorName');
    } catch (e, st) {
      print("❌ Error assigning branch: $e\n$st");
      rethrow;
    }
  }
}
