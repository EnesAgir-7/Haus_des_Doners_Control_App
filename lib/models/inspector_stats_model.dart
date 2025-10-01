import 'package:cloud_firestore/cloud_firestore.dart';

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
    final data = doc.data() as Map<String, dynamic>;
    return InspectorStatsModel(
      id: doc.id,
      inspectorId: data['inspectorId'] ?? '',
      month: data['month'] ?? 1,
      year: data['year'] ?? 2025,
      totalBranches: data['totalBranches'] ?? 0,
      completedInspections: data['completedInspections'] ?? 0,
      pendingInspections: data['pendingInspections'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inspectorId': inspectorId,
      'month': month,
      'year': year,
      'totalBranches': totalBranches,
      'completedInspections': completedInspections,
      'pendingInspections': pendingInspections,
      'averageScore': averageScore,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  int get remainingInspections =>
      totalBranches - completedInspections - pendingInspections;

  double get progressPercent {
    if (totalBranches == 0) return 0;
    return (completedInspections / totalBranches) * 100;
  }
}
