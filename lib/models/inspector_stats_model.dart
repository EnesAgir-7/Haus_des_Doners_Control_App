import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';

class InspectorStatsModel {
  final String id;
  final String inspectorId;
  final int month;
  final int year;
  final int totalBranches;
  final int completedInspections;
  final int pendingInspections;
  final double averageScore;
  final DateTime lastUpdated;

  InspectorStatsModel({
    required this.id,
    required this.inspectorId,
    required this.month,
    required this.year,
    required this.totalBranches,
    required this.completedInspections,
    required this.pendingInspections,
    required this.averageScore,
    required this.lastUpdated,
  });

  factory InspectorStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InspectorStatsModel(
      id: doc.id,
      inspectorId: data[InspectorStatsFields.inspectorId] ?? '',
      month: data[InspectorStatsFields.month] ?? 1,
      year: data[InspectorStatsFields.year] ?? DateTime.now().year,
      totalBranches: data[InspectorStatsFields.totalBranches] ?? 0,
      completedInspections:
          data[InspectorStatsFields.completedInspections] ?? 0,
      pendingInspections: data[InspectorStatsFields.pendingInspections] ?? 0,
      averageScore:
          (data[InspectorStatsFields.averageScore]?.toDouble() ?? 0.0),
      lastUpdated: data[InspectorStatsFields.lastUpdated] != null
          ? (data[InspectorStatsFields.lastUpdated] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      InspectorStatsFields.inspectorId: inspectorId,
      InspectorStatsFields.month: month,
      InspectorStatsFields.year: year,
      InspectorStatsFields.totalBranches: totalBranches,
      InspectorStatsFields.completedInspections: completedInspections,
      InspectorStatsFields.pendingInspections: pendingInspections,
      InspectorStatsFields.averageScore: averageScore,
      InspectorStatsFields.lastUpdated: Timestamp.fromDate(lastUpdated),
      
    };
  }

  /// Computed fields for progress metrics
  int get remainingInspections =>
      totalBranches - completedInspections - pendingInspections;

  double get progressPercent {
    if (totalBranches == 0) return 0;
    return (completedInspections / totalBranches) * 100;
  }
}
