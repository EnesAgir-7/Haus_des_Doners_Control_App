import 'package:cloud_firestore/cloud_firestore.dart';

class InspectorHistoryModel {
  final String inspectorId;
  final int totalInspections;
  final double avgScore;
  final int branchesVisited;
  final int tasksTotal;
  final int tasksCompleted;
  final List<double> recentScores;
  final List<String> vehicleIds; // Added field
  final List<String> branchesIds; // Added field
  final DateTime lastUpdated;

  InspectorHistoryModel({
    required this.inspectorId,
    required this.totalInspections,
    required this.avgScore,
    required this.branchesVisited,
    required this.tasksTotal,
    required this.tasksCompleted,
    required this.recentScores,
    required this.vehicleIds, // Added to constructor
    required this.branchesIds, // Added to constructor
    required this.lastUpdated,
  });

  factory InspectorHistoryModel.fromMap(Map<String, dynamic> data) {
    return InspectorHistoryModel(
      inspectorId: data['inspectorId'] ?? '',
      totalInspections: data['totalInspections'] ?? 0,
      avgScore: (data['avgScore']?.toDouble() ?? 0.0),
      branchesVisited: data['branchesVisited'] ?? 0,
      tasksTotal: data['tasksTotal'] ?? 0,
      tasksCompleted: data['tasksCompleted'] ?? 0,
      recentScores: data['recentScores'] != null
          ? List<double>.from(
              (data['recentScores'] as List<dynamic>).map((e) => e.toDouble()),
            )
          : [],
      vehicleIds:
          data['vehicleIds'] !=
              null // Added fromMap parsing
          ? List<String>.from(data['vehicleIds'] as List<dynamic>)
          : [],
      branchesIds:
          data['branchesIds'] !=
              null // Added fromMap parsing
          ? List<String>.from(data['branchesIds'] as List<dynamic>)
          : [],
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] is Timestamp
                ? (data['lastUpdated'] as Timestamp).toDate()
                : DateTime.parse(data['lastUpdated'].toString()))
          : DateTime.now(),
    );
  }

  factory InspectorHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return InspectorHistoryModel(
      inspectorId: data['inspectorId'] ?? '',
      totalInspections: data['totalInspections'] ?? 0,
      avgScore: (data['avgScore']?.toDouble() ?? 0.0),
      branchesVisited: data['branchesVisited'] ?? 0,
      tasksTotal: data['tasksTotal'] ?? 0,
      tasksCompleted: data['tasksCompleted'] ?? 0,
      recentScores: data['recentScores'] != null
          ? List<double>.from(
              (data['recentScores'] as List<dynamic>).map((e) => e.toDouble()),
            )
          : [],
      vehicleIds:
          data['vehicleIds'] !=
              null // Added fromFirestore parsing
          ? List<String>.from(data['vehicleIds'] as List<dynamic>)
          : [],
      branchesIds:
          data['branchesIds'] !=
              null // Added fromFirestore parsing
          ? List<String>.from(data['branchesIds'] as List<dynamic>)
          : [],
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inspectorId': inspectorId,
      'totalInspections': totalInspections,
      'avgScore': avgScore,
      'branchesVisited': branchesVisited,
      'tasksTotal': tasksTotal,
      'tasksCompleted': tasksCompleted,
      'recentScores': recentScores,
      'vehicleIds': vehicleIds, // Added toMap serialization
      'branchesIds': branchesIds, // Added toMap serialization
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
