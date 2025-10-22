import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inspector_history_model.dart';

Future<void> addDummyInspectorStats() async {
  final firestore = FirebaseFirestore.instance;

  // Dummy InspectorHistoryModel
  final dummyInspectorStats = InspectorHistoryModel(
    inspectorId: "lPHguCQTrBQr56aZCnjBfBgGVbk1",
    totalInspections: 25,
    avgScore: 8.4,
    tasksTotal: 15,
    tasksCompleted: 10,
    recentScores: ["6/20", "7/18", "8/12", "9/14", "8/12"],
    vehicleIds: [
      "1RqB9QmbXzIL2lj4FtTK",
      "Jfp245f0LcSVaiSLrgvc",
      "d7YLlUBkhyvxkUTRQgqs",
    ],
    branchesIds: ["branch_bakirkoy", "branch_besiktas", "branch_beyoglu"],
    lastUpdated: DateTime.now(),
  );

  await firestore
      .collection('inspector_stats')
      .doc(dummyInspectorStats.inspectorId)
      .set(dummyInspectorStats.toMap());

  print("✅ Dummy inspector stats added!");
}
