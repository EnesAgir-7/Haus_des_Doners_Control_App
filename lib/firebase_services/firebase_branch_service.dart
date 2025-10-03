import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/console.dart';

import '../models/branch_model.dart';

class BranchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'branches';

  // Get branches assigned to inspector
  Future<List<BranchModel>> getBranchesByInspector(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('assignedInspectorId', isEqualTo: inspectorId)
          .where('status', isEqualTo: 'active')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      console('Error getting branches by inspector: $e');
      return [];
    }
  }

  

  // Stream branches by inspector (real-time)
  Stream<List<BranchModel>> streamBranchesByInspector(String inspectorId) {
    return _db
        .collection(_collection)
        .where('assignedInspectorId', isEqualTo: inspectorId)
        .where('status', isEqualTo: 'active')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BranchModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get all branches (admin)
  Future<List<BranchModel>> getAllBranches() async {
    try {
      final snapshot = await _db.collection(_collection).orderBy('name').get();

      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      console('Error getting all branches: $e');
      return [];
    }
  }

  // Stream all branches (admin, real-time)
  Stream<List<BranchModel>> streamAllBranches() {
    return _db
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BranchModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get single branch by ID
  Future<BranchModel?> getBranchById(String branchId) async {
    try {
      final doc = await _db.collection(_collection).doc(branchId).get();
      if (!doc.exists) return null;
      return BranchModel.fromFirestore(doc);
    } catch (e) {
      console('Error getting branch: $e');
      return null;
    }
  }

  // Create branch
  Future<String> createBranch(BranchModel branch) async {
    try {
      final docRef = await _db.collection(_collection).add(branch.toMap());
      return docRef.id;
    } catch (e) {
      console('Error creating branch: $e');
      rethrow;
    }
  }

  // Update branch
  Future<void> updateBranch(String branchId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection(_collection).doc(branchId).update(data);
    } catch (e) {
      console('Error updating branch: $e');
      rethrow;
    }
  }

  // Delete branch
  Future<void> deleteBranch(String branchId) async {
    try {
      await _db.collection(_collection).doc(branchId).delete();
    } catch (e) {
      console('Error deleting branch: $e');
      rethrow;
    }
  }

  // Assign branch to inspector
  Future<void> assignBranchToInspector(
    String branchId,
    String inspectorId,
  ) async {
    try {
      await _db.collection(_collection).doc(branchId).update({
        'assignedInspectorId': inspectorId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console('Error assigning branch: $e');
      rethrow;
    }
  }


}
