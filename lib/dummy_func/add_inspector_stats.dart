import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addDummyInspectorStats() async {
  final firestore = FirebaseFirestore.instance;
  const inspectorId = "lPHguCQTrBQr56aZCnjBfBgGVbk1";

  final monthsData = {
    "01-2025": {
      "totalInspections": 10,
      "avgScore": 7.8,
      "tasksTotal": 12,
      "tasksCompleted": 9,
      "recentScores": ["8/15", "7/14", "9/16"],
      "vehicleIds": ["veh1", "veh2"],
      "branchesIds": ["branch_bakirkoy"],
      "lastUpdated": Timestamp.now(),
    },
    "02-2025": {
      "totalInspections": 15,
      "avgScore": 8.5,
      "tasksTotal": 20,
      "tasksCompleted": 15,
      "recentScores": ["8/12", "9/10", "8/14", "9/15"],
      "vehicleIds": ["veh1", "veh3"],
      "branchesIds": ["branch_besiktas"],
      "lastUpdated": Timestamp.now(),
    },
    "03-2025": {
      "totalInspections": 25,
      "avgScore": 9.1,
      "tasksTotal": 22,
      "tasksCompleted": 20,
      "recentScores": ["9/18", "9/19", "10/20"],
      "vehicleIds": ["veh2", "veh4"],
      "branchesIds": ["branch_beyoglu"],
      "lastUpdated": Timestamp.now(),
    },
  };

  await firestore.collection('inspector_history').doc(inspectorId).set({
    "inspectorId": inspectorId,
    "lastUpdated": Timestamp.now(),
    ...monthsData,
  }, SetOptions(merge: true));

  print("✅ Dummy monthly stats saved under inspector document!");
}
