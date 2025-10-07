import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/console.dart';

import '../core/constants/firebase_constants.dart';
import '../models/branch_model.dart';
import '../models/route_model.dart';

class BranchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionBranches = Collections.branches;
  final String _collectionRoutes = Collections.routes;

  // Get all branches
  Future<List<BranchModel>> getAllBranches() async {
    try {
      final snapshot = await _db.collection(_collectionBranches).get();
      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      console('Error getting all branches: $e');
      return [];
    }
  }

  // Get all branches assigned to an inspector
  Future<List<BranchModel>> getInspectorBranches(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collectionBranches)
          .where('assignedInspectorId', isEqualTo: inspectorId)
          .get();

      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      console('Error getting inspector branches: $e');
      return [];
    }
  }

  // Get active branches assigned to inspector
  Future<List<BranchModel>> getBranchesByInspector(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collectionBranches)
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
        .collection(_collectionBranches)
        .where('assignedInspectorId', isEqualTo: inspectorId)
        .where('status', isEqualTo: 'active')
        .orderBy(AppConstants.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BranchModel.fromFirestore(doc))
              .toList(),
        );
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

  // Get single branch by ID
  Future<BranchModel?> getBranchById(String branchId) async {
    try {
      final doc = await _db.collection(_collectionBranches).doc(branchId).get();
      if (!doc.exists) return null;
      return BranchModel.fromFirestore(doc);
    } catch (e) {
      console('Error getting branch: $e');
      return null;
    }
  }

  Future<void> assignBranchToHimself({
    required String inspectorId,
    required String inspectorName,
    required String branchId,
    required String branchName,
    required String timeSlot,
  }) async {
    try {
      final routeDocRef = _db.collection(_collectionRoutes).doc(inspectorId);

      // 1. Check if a route document already exists for this inspector
      final docSnap = await routeDocRef.get();

      if (!docSnap.exists) {
        // 2. Create a new route document directly under inspectorId
        final route = RouteModel(
          id: inspectorId,
          date: DateTime.now(),
          inspectorId: inspectorId,
          inspectorName: inspectorName,
          stops: [
            RouteStopModel(
              timeSlot: timeSlot,
              branchId: branchId,
              branchName: branchName,
              status: AppConstants.pending,
              order: 1,
              inspectionId: inspectorId,
              createdAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await routeDocRef.set(route.toMap());
      } else {
        // 3. Append stop to existing route
        final route = RouteModel.fromFirestore(docSnap);
        final newStop = RouteStopModel(
          timeSlot: timeSlot,
          branchId: branchId,
          branchName: branchName,
          status: AppConstants.pending,
          order: route.stops.length + 1,
        );

        final updatedStops = [...route.stops, newStop];

        await routeDocRef.update({
          'stops': updatedStops.map((s) => s.toMap()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // 4. Update branch to mark as assigned
      await _db.collection(_collectionBranches).doc(branchId).update({
        'isAssigned': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      console('Branch assigned successfully');
    } catch (e) {
      print("Error assigning branch: $e");
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

  Future<void> removeBranchAssignment({
    required String inspectorId,
    required String branchId,
  }) async {
    try {
      final routeDocRef = _db.collection(_collectionRoutes).doc(inspectorId);

      final docSnap = await routeDocRef.get();
      if (!docSnap.exists) return;

      final route = RouteModel.fromFirestore(docSnap);
      final updatedStops = route.stops
          .where((s) => s.branchId != branchId)
          .toList();

      await routeDocRef.update({
        'stops': updatedStops.map((s) => s.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Mark branch as unassigned
      await _db.collection(_collectionBranches).doc(branchId).update({
        'isAssigned': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      console('Branch unassigned successfully');
    } catch (e) {
      print("Error removing branch assignment: $e");
      rethrow;
    }
  }
}
