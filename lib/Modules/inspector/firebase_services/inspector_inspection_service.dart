import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/Modules/admin/admin_firebase_services/admin_user_service.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';

import '../../../common_services/remote_config_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/inspection_model.dart';
import '../../../models/inspection_template_model.dart';
import '../../../models/route_model.dart';

class InspectorInspectionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = Collections.inspections;
  final String _collectionBranches = Collections.branches;
  final String _collectionRoutes = Collections.routes;
  final remoteConfig = RemoteConfigService();

  // Get inspections by branch
  Future<List<InspectionModel>> getInspectionsByBranch(String branchId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where(InspectionFields.branchId, isEqualTo: branchId)
          .orderBy(InspectionFields.scheduledTime, descending: true)
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
          .where(InspectionFields.branchId, isEqualTo: branchId)
          .orderBy(InspectionFields.scheduledTime, descending: true)
          .limit(10)
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
  Stream<List<InspectionModel>> streamLast10Inspections(
    String branchId,
    String inspectorId,
  ) {
    return _db
        .collection(_collection)
        .where(InspectionFields.branchId, isEqualTo: branchId)
        .orderBy(InspectionFields.scheduledTime, descending: true)
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
          .where(InspectionFields.inspectorId, isEqualTo: inspectorId)
          .orderBy(InspectionFields.scheduledTime, descending: true)
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
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _db
          .collection(_collection)
          .where(InspectionFields.inspectorId, isEqualTo: inspectorId)
          .where(
            InspectionFields.scheduledTime,
            isGreaterThanOrEqualTo: startOfDay,
          )
          .where(InspectionFields.scheduledTime, isLessThan: endOfDay)
          .orderBy(InspectionFields.scheduledTime)
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
        query = query.where(
          InspectionFields.scheduledTime,
          isGreaterThanOrEqualTo: startDate,
        );
      }
      if (endDate != null) {
        query = query.where(
          InspectionFields.scheduledTime,
          isLessThanOrEqualTo: endDate,
        );
      }

      final snapshot = await query
          .orderBy(InspectionFields.scheduledTime, descending: true)
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

      await AdminUserService().updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: inspection.inspectorId,
        updates: {
          IHF.totalInspections: FieldValue.increment(1),
          IHF.recentScores: [inspection.score.toString()],
        },
      );

      // await batch.commit();
      // if (remoteConfig.enableNotifications)
      //  {
      //    NotificationHelper.instance.sendNotificationToTopic(
      //     topic: AppConstants.adminTopic,
      //     title: LocaleKeys.newInspectionSubmitted.tr(),
      //     body: LocaleKeys.newInspectionBody.tr().replaceFirst(
      //       '{branchName}',
      //       inspection.branchName,
      //     ),
      //     data: {
      //       'type': 'inspection_submitted',
      //       'branchId': inspection.branchId,
      //     },
      //   );
      //  }
      return docRef.id;
    } catch (e, st) {
      print('Error creating inspection: $e\n$st');
      rethrow;
    }
  }

  Future<void> _prepareBranchStatisticsBatch({
    required WriteBatch batch,
    required String branchId,
    required String inspectionScore,
  }) async {
    final branchRef = _db.collection(_collectionBranches).doc(branchId);
    final branchDoc = await branchRef.get();

    if (!branchDoc.exists) throw Exception(LocaleKeys.branch_not_found);

    final data = branchDoc.data()!;
    final currentTotal = data[BranchFields.totalInspections] ?? 0;
    final newTotal = currentTotal + 1;

    // ✅ Get current cumulative average score (stored as "totalPoints/totalPossible")
    final dynamic currentAverageData = data[BranchFields.averageScore];
    String currentAverageScoreStr = "0/0";

    // Handle both old (double), new (string), and null (first inspection) format
    if (currentAverageData == null) {
      currentAverageScoreStr = "0/0";
    } else if (currentAverageData is String) {
      currentAverageScoreStr = currentAverageData;
    } else if (currentAverageData is double || currentAverageData is int) {
      currentAverageScoreStr = "0/0";
    }

    final currentParts = currentAverageScoreStr.split('/');
    final currentPoints =
        int.tryParse(currentParts.isNotEmpty ? currentParts[0] : "0") ?? 0;
    final currentPossible =
        int.tryParse(currentParts.length > 1 ? currentParts[1] : "0") ?? 0;

    // ✅ Parse new inspection score "8.0/14" and convert to int
    final inspectionParts = inspectionScore.split('/');
    final newPoints = (double.tryParse(inspectionParts[0]) ?? 0.0).toInt();
    final newPossible =
        (double.tryParse(
                  inspectionParts.length > 1 ? inspectionParts[1] : "0",
                ) ??
                0.0)
            .toInt();

    // ✅ Accumulate: 0/0 + 8/14 = 8/14
    final totalPoints = currentPoints + newPoints;
    final totalPossible = currentPossible + newPossible;
    final newAverageScore = "$totalPoints/$totalPossible";

    // ✅ Handle last 12 scores
    final List<String> currentScores = List<String>.from(
      data[BranchFields.last12MonthsScores] ?? [],
    );

    currentScores.add(inspectionScore);

    // Keep only the last 12
    final trimmedScores = currentScores.length > 12
        ? currentScores.sublist(currentScores.length - 12)
        : currentScores;

    // ✅ Update Firestore fields
    batch.update(branchRef, {
      BranchFields.totalInspections: newTotal,
      BranchFields.lastInspectionDate: FieldValue.serverTimestamp(),
      BranchFields.averageScore: newAverageScore, // ✅ Only field for scoring
      BranchFields.stop: null,
      BranchFields.lastInspectionScore: inspectionScore,
      BranchFields.last12MonthsScores: trimmedScores,
      BranchFields.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Helper: adds route stop update to batch
  Future<void> _prepareStopCompletionBatch({
    required WriteBatch batch,
    required String inspectorId,
    required String branchId,
    required String inspectionId,
    required String score,
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
          expiryDate: Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 1)),
          ),
        );
      }
      return stop;
    }).toList();

    batch.update(routeRef, {
      RouteFields.stops: updatedStops.map((s) => s.toMap()).toList(),
      RouteFields.updatedAt: Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<InspectionTemplate?> getTemplateById(String templateId) async {
    try {
      final doc = await _db
          .collection(Collections.inspectionTemplates)
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
