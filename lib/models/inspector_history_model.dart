import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../common_services/firebase_error_helper.dart';

class InspectorHistoryModel {
  final String inspectorId;
  final int totalInspections;
  final int tasksTotal;
  final int tasksCompleted;
  final List<String> recentScores;
  final List<String> vehicleIds;
  final List<String> branchesIds;
  final DateTime lastUpdated;

  InspectorHistoryModel({
    required this.inspectorId,
    required this.totalInspections,
    required this.tasksTotal,
    required this.tasksCompleted,
    required this.recentScores,
    required this.vehicleIds,
    required this.branchesIds,
    required this.lastUpdated,
  });

  /// 🧩 Create instance from Firestore map
  factory InspectorHistoryModel.fromMap(Map<String, dynamic> data) {
    return InspectorHistoryModel(
      inspectorId: data[IHF.inspectorId] ?? '',
      totalInspections: data[IHF.totalInspections] ?? 0,
      tasksTotal: data[IHF.tasksTotal] ?? 0,
      tasksCompleted: data[IHF.tasksCompleted] ?? 0,
      recentScores: data[IHF.recentScores] != null
          ? (data[IHF.recentScores] as List<dynamic>)
                .map<String>((e) => e.toString())
                .toList()
          : [],
      vehicleIds: data[IHF.vehicleIds] != null
          ? List<String>.from(data[IHF.vehicleIds] as List)
          : [],
      branchesIds: data[IHF.branchesIds] != null
          ? List<String>.from(data[IHF.branchesIds] as List)
          : [],
      // ✅ FIXED: Using FirestoreHelpers
      lastUpdated: FirestoreHelpers.parseTimestamp(
        data[IHF.lastUpdated],
        fallback: DateTime.now(),
      ),
    );
  }

  /// 🧩 Create instance directly from Firestore snapshot
  factory InspectorHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InspectorHistoryModel.fromMap(data);
  }

  /// 🧩 Convert model to Firestore map
  Map<String, dynamic> toMap() {
    return {
      IHF.inspectorId: inspectorId,
      IHF.totalInspections: totalInspections,
      IHF.tasksTotal: tasksTotal,
      IHF.tasksCompleted: tasksCompleted,
      IHF.recentScores: recentScores,
      IHF.vehicleIds: vehicleIds,
      IHF.branchesIds: branchesIds,
      IHF.lastUpdated: Timestamp.fromDate(lastUpdated),
    };
  }

}

class InspectorAllMonthsData {
  final String inspectorId;
  final List<String> availableMonths; // ["01-2025", "02-2025", ...]
  final DateTime lastUpdated;

  InspectorAllMonthsData({
    required this.inspectorId,
    required this.availableMonths,
    required this.lastUpdated,
  });
}
