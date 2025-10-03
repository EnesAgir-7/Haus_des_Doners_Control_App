import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/console.dart';

import '../models/branch_model.dart';
import '../models/route_model.dart';

class BranchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'branches';
  final String _collectionRoutes = 'routes';

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

  /// Assign branch to inspector persistently (not date-specific)
  Future<void> assignBranchToHimself({
    required String inspectorId,
    required String inspectorName,
    required String branchId,
    required String branchName,
    required String timeSlot,
  }) async {
    try {
      // Check if inspector already has a route
      final query = await _db
          .collection(_collection)
          .where('inspectorId', isEqualTo: inspectorId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Create new route for inspector
        final newRouteRef = _db.collection(_collectionRoutes).doc();
        final route = RouteModel(
          id: newRouteRef.id,
          date: DateTime.now(), // can keep creation date
          inspectorId: inspectorId,
          inspectorName: inspectorName,
          stops: [
            RouteStopModel(
              timeSlot: timeSlot,
              branchId: branchId,
              branchName: branchName,
              status: 'current',
              order: 1,
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await newRouteRef.set(route.toMap());
      } else {
        // Append stop to existing route
        final doc = query.docs.first;
        final route = RouteModel.fromFirestore(doc);

        final newStop = RouteStopModel(
          timeSlot: timeSlot,
          branchId: branchId,
          branchName: branchName,
          status: 'pending',
          order: route.stops.length + 1,
        );

        final updatedStops = [...route.stops, newStop];

        await doc.reference.update({
          'stops': updatedStops.map((s) => s.toMap()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      print("Error assigning branch: $e");
      rethrow;
    }
  }
}
