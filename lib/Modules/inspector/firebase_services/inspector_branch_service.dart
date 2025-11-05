import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/core/console.dart';

import '../../../common_services/notification_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/branch_model.dart';
import '../../../models/route_model.dart';
import '../../../translations/locale_keys.g.dart';

class InspectorBranchService {
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
          .where(BranchFields.assignedInspectorId, isEqualTo: inspectorId)
          .get();

      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      console('Error getting inspector branches: $e');
      return [];
    }
  }

  // Fetch branch by ID (one-time)
  Future<BranchModel?> getBranchById(String branchId) async {
    try {
      final docSnap = await _db
          .collection(_collectionBranches)
          .doc(branchId)
          .get();

      if (!docSnap.exists) {
        print('No branch found with id: $branchId');
        return null;
      }

      return BranchModel.fromFirestore(docSnap);
    } catch (e) {
      print('Error fetching branch: $e');
      return null;
    }
  }

  // Get active branches assigned to inspector
  Future<List<BranchModel>> getBranchesByInspector(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collectionBranches)
          .where(BranchFields.assignedInspectorId, isEqualTo: inspectorId)
          .where(BranchFields.status, isEqualTo: AppConstants.active)
          .orderBy(AppConstants.name)
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
        .where(BranchFields.assignedInspectorId, isEqualTo: inspectorId)
        .where(BranchFields.status, isEqualTo: AppConstants.active)
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

  Future<void> updateStopTimeSlot({
    required String inspectorId,
    required String branchId,
    required int order,
    required String newTimeSlot,
  }) async {
    try {
      final routeDocRef = _db.collection(_collectionRoutes).doc(inspectorId);
      final branchDocRef = _db.collection(_collectionBranches).doc(branchId);
      final now = DateTime.now();

      final docSnap = await routeDocRef.get();
      if (!docSnap.exists) {
        throw Exception(LocaleKeys.noRouteFound.tr());
      }

      final route = RouteModel.fromFirestore(docSnap);

      final stopIndex = route.stops.indexWhere((s) => s.order == order);
      if (stopIndex == -1) {
        throw Exception(
          LocaleKeys.noStopFound.tr().replaceFirst('{order}', order.toString()),
        );
      }

      final updatedStop = route.stops[stopIndex].copyWith(
        timeSlot: newTimeSlot,
      );

      final updatedStops = [...route.stops];
      updatedStops[stopIndex] = updatedStop;

      final batch = _db.batch();

      // Update route doc
      batch.update(routeDocRef, {
        RouteFields.stops: updatedStops.map((s) => s.toMap()).toList(),
        RouteFields.updatedAt: Timestamp.fromDate(now),
      });

      // Update branch doc
      batch.update(branchDocRef, {
        BranchFields.stop: updatedStop.toMap(),
        BranchFields.createdAt: Timestamp.fromDate(now),
      });

      // Commit the batch
      await batch.commit();

      console('✅ Stop timeSlot updated successfully for order: $order');
    } catch (e, st) {
      print("❌ Error updating stop timeSlot: $e\n$st");
      rethrow;
    }
  }

  Future<void> assignRoute({
    required String inspectorId,
    required String inspectorName,
    required String branchId,
    required String branchName,
    required String branchAddress,
    required String timeSlot,
    required String branchTemplateId,
  }) async {
    try {
      final routeDocRef = _db.collection(_collectionRoutes).doc(inspectorId);
      final branchDocRef = _db.collection(_collectionBranches).doc(branchId);

      final now = DateTime.now();

      final batch = _db.batch();
      final routeSnapshot = await routeDocRef.get();

      RouteStopModel stopToSave;

      if (!routeSnapshot.exists) {
        // first stop → order 1
        stopToSave = RouteStopModel(
          branchTemplateId: branchTemplateId,
          timeSlot: timeSlot,
          branchId: branchId,
          branchName: branchName,
          branchAddress: branchAddress,
          status: AppConstants.pending,
          order: 1,
          createdAt: now,
        );

        final route = RouteModel(
          id: inspectorId,
          date: now,
          inspectorId: inspectorId,
          inspectorName: inspectorName,
          stops: [stopToSave],
          createdAt: now,
          updatedAt: now,
        );

        batch.set(routeDocRef, route.toMap());
      } else {
        final data = routeSnapshot.data() as Map<String, dynamic>;
        final stops = (data[RouteFields.stops] as List?) ?? [];

        final alreadyAssigned = stops.any(
          (s) => s[RouteStopFields.branchId] == branchId,
        );
        if (alreadyAssigned) {
          throw Exception(LocaleKeys.branchAlreadyAssigned.tr());
        }

        final orderNumber = stops.length + 1;

        stopToSave = RouteStopModel(
          branchTemplateId: branchTemplateId,
          timeSlot: timeSlot,
          branchId: branchId,
          branchName: branchName,
          branchAddress: branchAddress,
          status: AppConstants.pending,
          order: orderNumber,
          createdAt: now,
        );

        final updatedStops = [...stops, stopToSave.toMap()];

        batch.update(routeDocRef, {
          RouteFields.stops: updatedStops,
          RouteFields.updatedAt: Timestamp.fromDate(now),
        });
      }

      // ✅ Use the same stopToSave (with correct order)
      batch.update(branchDocRef, {
        BranchFields.stop: stopToSave.toMap(),
        RouteFields.updatedAt: Timestamp.fromDate(now),
      });

      await batch.commit();

      // // Send to multiple inspectors
      // Send notification only if tokens exist
      if (loggedInUser?.fcmTokens != null &&
          loggedInUser!.fcmTokens!.isNotEmpty) {
         await FCMHelper.instance.sendNotificationToMultipleTokens(
          fcmTokens: loggedInUser!.fcmTokens!,
          title: 'Route Assigned',
          body:
              'You have assigned ${stopToSave.branchName} to your route. Please be ready at $timeSlot',
          data: {'type': 'route_assigned', 'branchId': branchId},
        );
      } else {
        console('⚠️ No FCM tokens available');
      }
      console('✅ Branch assigned successfully to inspector $inspectorName');
    } catch (e, st) {
      print("❌ Error assigning branch with batch: $e\n$st");
      rethrow;
    }
  }

  Future<void> unAssignRouteAndFreeTheBranch({
    required String inspectorId,
    required String branchId,
  }) async {
    try {
      final routeDocRef = _db.collection(_collectionRoutes).doc(inspectorId);
      final branchDocRef = _db.collection(_collectionBranches).doc(branchId);

      final docSnap = await routeDocRef.get();
      if (!docSnap.exists) return;

      final route = RouteModel.fromFirestore(docSnap);
      final updatedStops = route.stops
          .where((s) => s.branchId != branchId)
          .toList();

      final batch = _db.batch();

      // Update route stops
      batch.update(routeDocRef, {
        RouteFields.stops: updatedStops.map((s) => s.toMap()).toList(),
        RouteFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      });

      // Remove branch assignment
      batch.update(branchDocRef, {
        BranchFields.stop: null,
        BranchFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();

      console('✅ This route is removed');
    } catch (e, st) {
      print("❌ Error removing branch assignment: $e\n$st");
      rethrow;
    }
  }
}
