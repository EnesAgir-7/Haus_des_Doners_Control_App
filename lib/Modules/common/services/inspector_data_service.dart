import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/models/inspection_model.dart';
import 'package:haus_des_control/models/task_model.dart';
import 'package:haus_des_control/models/vehicle_model.dart';

class InspectorDataService {
  static Stream<List<TaskModel>> streamTasks(
    String inspectorId,
    int year,
    int month,
  ) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection(Collections.tasks)
        .where(TaskFields.assignedInspectorId, isEqualTo: inspectorId)
        .where(
          TaskFields.createdAt,
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          TaskFields.createdAt,
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        )
        .orderBy(TaskFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  static Stream<List<InspectionModel>> streamInspections(
    String inspectorId,
    int year,
    int month,
  ) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection(Collections.inspections)
        .where(InspectionFields.inspectorId, isEqualTo: inspectorId)
        .where(
          InspectionFields.completedTime,
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          InspectionFields.completedTime,
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        )
        .orderBy(InspectionFields.completedTime, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InspectionModel.fromFirestore(doc))
              .toList(),
        );
  }

  static Stream<List<VehicleModel>> streamVehicles(
    String inspectorId,
    int year,
    int month,
    List<String> vehicleIds,
  ) {
    if (vehicleIds.isEmpty) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection(Collections.vehicles)
        .where(FieldPath.documentId, whereIn: vehicleIds)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VehicleModel.fromFirestore(doc))
              .toList(),
        );
  }
}
