import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../models/inspection_model.dart';
import '../models/inspection_template_model.dart';
import '../models/route_model.dart';

class InspectionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = Collections.inspections;
  final String _collectionBranches = Collections.branches;
  final String _collectionRoutes = Collections.routes;

  // Get inspections by branch
  Future<List<InspectionModel>> getInspectionsByBranch(String branchId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('branchId', isEqualTo: branchId)
          .orderBy('scheduledTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting inspections by branch: $e');
      return [];
    }
  }

  Future<List<InspectionModel>> getLastTenInspectionsByBranch(
    String branchId,
  ) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('branchId', isEqualTo: branchId)
          .orderBy('scheduledTime', descending: true)
          .limit(10) // ✅ Get only last 10 inspections
          .get();

      return snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting inspections by branch: $e');
      return [];
    }
  }

  // Stream inspections by branch (real-time)
  Stream<List<InspectionModel>> streamInspectionsByBranch(String branchId) {
    return _db
        .collection(_collection)
        .where('branchId', isEqualTo: branchId)
        .orderBy('scheduledTime', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InspectionModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get inspections by inspector
  Future<List<InspectionModel>> getInspectionsByInspector(
    String inspectorId,
  ) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('inspectorId', isEqualTo: inspectorId)
          .orderBy('scheduledTime', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting inspections by inspector: $e');
      return [];
    }
  }

  // Get today's inspections for inspector
  Future<List<InspectionModel>> getTodaysInspections(String inspectorId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final snapshot = await _db
          .collection(_collection)
          .where('inspectorId', isEqualTo: inspectorId)
          .where('scheduledTime', isGreaterThanOrEqualTo: startOfDay)
          .where('scheduledTime', isLessThan: endOfDay)
          .orderBy('scheduledTime')
          .get();

      return snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting today\'s inspections: $e');
      return [];
    }
  }

  // Get all inspections (admin)
  Future<List<InspectionModel>> getAllInspections({
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _db.collection(_collection);

      if (startDate != null) {
        query = query.where('scheduledTime', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('scheduledTime', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query
          .orderBy('scheduledTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all inspections: $e');
      return [];
    }
  }

  // Get single inspection
  Future<InspectionModel?> getInspectionById(String inspectionId) async {
    try {
      final doc = await _db.collection(_collection).doc(inspectionId).get();
      if (!doc.exists) return null;
      return InspectionModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting inspection: $e');
      return null;
    }
  }

  Future<String> createInspection(InspectionModel inspection) async {
    console('Creating inspection...');
    final batch = _db.batch();
    try {
      // Pre-generate docRef for the inspection
      final docRef = _db.collection(_collection).doc();
      batch.set(docRef, inspection.toMap());

      // Prepare branch statistics update
      await _prepareBranchStatisticsBatch(
        batch: batch,
        branchId: inspection.branchId,
        inspectionScore: inspection.score,
      );

      // Prepare route stop update
      await _prepareStopCompletionBatch(
        batch: batch,
        inspectorId: inspection.inspectorId,
        branchId: inspection.branchId,
        inspectionId: docRef.id,
        score: inspection.score,
      );

      await batch.commit();

      return docRef.id;
    } catch (e, st) {
      print('Error creating inspection: $e\n$st');
      rethrow;
    }
  }

  // Helper: adds branch statistics update to batch
  Future<void> _prepareBranchStatisticsBatch({
    required WriteBatch batch,
    required String branchId,
    required double inspectionScore,
  }) async {
    final branchRef = _db.collection(_collectionBranches).doc(branchId);
    final branchDoc = await branchRef.get();
    if (!branchDoc.exists) throw Exception('Branch not found');

    final data = branchDoc.data()!;
    final currentTotal = data['totalInspections'] ?? 0;
    final currentAverage = (data['averageRating'] ?? 0.0).toDouble();
    final newTotal = currentTotal + 1;
    final newAverage =
        ((currentAverage * currentTotal) + inspectionScore) / newTotal;

    batch.update(branchRef, {
      'totalInspections': newTotal,
      'lastInspectionDate': FieldValue.serverTimestamp(),
      'averageRating': newAverage,
      'stop': null,
      'lastInspectionScore': inspectionScore,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Helper: adds route stop update to batch
  Future<void> _prepareStopCompletionBatch({
    required WriteBatch batch,
    required String inspectorId,
    required String branchId,
    required String inspectionId,
    required double score,
    String status = AppConstants.completed,
  }) async {
    final routeRef = _db.collection(_collectionRoutes).doc(inspectorId);
    final docSnap = await routeRef.get();
    if (!docSnap.exists) return;

    final route = RouteModel.fromFirestore(docSnap);
    final updatedStops = route.stops.map((stop) {
      if (stop.branchId == branchId) {
        return stop.copyWith(
          status: status,
          inspectionId: inspectionId,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
          inspectionScore: score,
          expiryDate: Timestamp.fromDate(DateTime.now().add(Duration(days: 1))),
        );
      }
      return stop;
    }).toList();

    batch.update(routeRef, {
      'stops': updatedStops.map((s) => s.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // // Create inspection
  // Future<String> createInspection(InspectionModel inspection) async {
  //   console('Creating inspection...');
  //   try {
  //     final docRef = await _db.collection(_collection).add(inspection.toMap());
  //     // Update branch statistics
  //     Future.wait([
  //       updateBranchStatistics(
  //         branchId: inspection.branchId,
  //         inspectionScore: inspection.score,
  //       ),

  //       // 2. Update the route stop to mark as completed
  //       completeStopInspection(
  //         inspectorId: inspection.inspectorId,
  //         branchId: inspection.branchId,
  //         inspectionId: docRef.id,
  //         status: AppConstants.completed,
  //         score: inspection.score,
  //       ),
  //     ]);

  //     return docRef.id;
  //   } catch (e) {
  //     print('Error creating inspection: $e');
  //     rethrow;
  //   }
  // }

  // Future<void> completeStopInspection({
  //   required String inspectorId,
  //   required String branchId,
  //   required String inspectionId,
  //   required double score,
  //   String status = AppConstants.completed,
  // }) async {
  //   try {
  //     final routeDocRef = _db.collection(_collectionRoutes).doc(inspectorId);
  //     final docSnap = await routeDocRef.get();

  //     if (!docSnap.exists) {
  //       print("No route found for inspector $inspectorId");
  //       return;
  //     }

  //     final route = RouteModel.fromFirestore(docSnap);

  //     // Find the stop that matches the branch
  //     final updatedStops = route.stops.map((stop) {
  //       if (stop.branchId == branchId) {
  //         return stop.copyWith(
  //           status: status,
  //           inspectionId: inspectionId,
  //           createdAt: DateTime.now(),
  //           completedAt: DateTime.now(),
  //           inspectionScore: score,
  //           expiryDate: Timestamp.fromDate(
  //             DateTime.now().add(Duration(days: 1)),
  //           ),
  //         );
  //       }
  //       return stop;
  //     }).toList();

  //     await routeDocRef.update({
  //       'stops': updatedStops.map((s) => s.toMap()).toList(),
  //       'updatedAt': Timestamp.fromDate(DateTime.now()),
  //     });

  //     print('Route stop updated successfully for branch $branchId');
  //   } catch (e) {
  //     print('Error updating route stop status: $e');
  //   }
  // }

  // Future<void> updateBranchStatistics({
  //   required String branchId,
  //   required double inspectionScore,
  // }) async {
  //   try {
  //     final branchRef = _db.collection(_collectionBranches).doc(branchId);

  //     // Get current branch data
  //     final branchDoc = await branchRef.get();

  //     if (!branchDoc.exists) {
  //       throw Exception('Branch not found');
  //     }

  //     final currentData = branchDoc.data()!;
  //     final currentTotal = currentData['totalInspections'] ?? 0;
  //     final currentAverage = (currentData['averageRating'] ?? 0.0).toDouble();

  //     // Calculate new average
  //     final newTotal = currentTotal + 1;
  //     final newAverage =
  //         ((currentAverage * currentTotal) + inspectionScore) / newTotal;

  //     // Update branch document
  //     await branchRef.update({
  //       'totalInspections': newTotal,
  //       'lastInspectionDate': FieldValue.serverTimestamp(),
  //       'averageRating': newAverage,
  //       'nextInspectionDate': null,
  //       'lastInspectionScore': inspectionScore,
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     });

  //     print('Branch statistics updated: Total=$newTotal, Avg=$newAverage');
  //   } catch (e) {
  //     print('Error updating branch statistics: $e');
  //     rethrow;
  //   }
  // }

  // Delete inspection
  Future<void> deleteInspection(String inspectionId) async {
    try {
      await _db.collection(_collection).doc(inspectionId).delete();
    } catch (e) {
      print('Error deleting inspection: $e');
      rethrow;
    }
  }

  // Fetches the single template document by its ID
  Future<InspectionTemplate?> getTemplateById(String templateId) async {
    try {
      final doc = await _db
          .collection('inspectionTemplates')
          .doc(templateId)
          .get();
      if (!doc.exists) {
        print('Template with ID $templateId not found.');
        return null;
      }
      return InspectionTemplate.fromFirestore(doc);
    } catch (e) {
      print('Error getting template: $e');
      rethrow;
    }
  }
}
