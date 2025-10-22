import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

class InspectorHistoryModel {
  final String inspectorId;
  final int totalInspections;
  final double avgScore;
  final int tasksTotal;
  final int tasksCompleted;
  final List<double> recentScores;
  final List<String> vehicleIds;
  final List<String> branchesIds;
  final DateTime lastUpdated;

  InspectorHistoryModel({
    required this.inspectorId,
    required this.totalInspections,
    required this.avgScore,
    required this.tasksTotal,
    required this.tasksCompleted,
    required this.recentScores,
    required this.vehicleIds,
    required this.branchesIds,
    required this.lastUpdated,
  });

  factory InspectorHistoryModel.fromMap(Map<String, dynamic> data) {
    return InspectorHistoryModel(
      inspectorId: data[InspectorHistoryFields.inspectorId] ?? '',
      totalInspections: data[InspectorHistoryFields.totalInspections] ?? 0,
      avgScore: (data[InspectorHistoryFields.avgScore]?.toDouble() ?? 0.0),
      tasksTotal: data[InspectorHistoryFields.tasksTotal] ?? 0,
      tasksCompleted: data[InspectorHistoryFields.tasksCompleted] ?? 0,
      recentScores: data[InspectorHistoryFields.recentScores] != null
          ? List<double>.from(
              (data[InspectorHistoryFields.recentScores] as List<dynamic>).map(
                (e) => e.toDouble(),
              ),
            )
          : [],
      vehicleIds: data[InspectorHistoryFields.vehicleIds] != null
          ? List<String>.from(data[InspectorHistoryFields.vehicleIds] as List)
          : [],
      branchesIds: data[InspectorHistoryFields.branchesIds] != null
          ? List<String>.from(data[InspectorHistoryFields.branchesIds] as List)
          : [],
      lastUpdated: data[InspectorHistoryFields.lastUpdated] != null
          ? (data[InspectorHistoryFields.lastUpdated] is Timestamp
                ? (data[InspectorHistoryFields.lastUpdated] as Timestamp)
                      .toDate()
                : DateTime.parse(
                    data[InspectorHistoryFields.lastUpdated].toString(),
                  ))
          : DateTime.now(),
    );
  }

  factory InspectorHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InspectorHistoryModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      InspectorHistoryFields.inspectorId: inspectorId,
      InspectorHistoryFields.totalInspections: totalInspections,
      InspectorHistoryFields.avgScore: avgScore,
      InspectorHistoryFields.tasksTotal: tasksTotal,
      InspectorHistoryFields.tasksCompleted: tasksCompleted,
      InspectorHistoryFields.recentScores: recentScores,
      InspectorHistoryFields.vehicleIds: vehicleIds,
      InspectorHistoryFields.branchesIds: branchesIds,
      InspectorHistoryFields.lastUpdated: Timestamp.fromDate(lastUpdated),
    };
  }
}
