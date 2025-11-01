import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';

import '../../../core/console.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/vehicle_model.dart';
import 'admin_user_service.dart';

class AdminVehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionVehicles = Collections.vehicles;
  final AdminUserService _userService = AdminUserService();
  // Stream vehicle by inspector (real-time)
  Stream<List<VehicleModel>> streamAllVehicles() {
    return _db
        .collection(_collectionVehicles)
        .orderBy(VehicleFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VehicleModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateVehicleWithBatch({
    required String vehicleId,
    int? newKm,
    String? newPlate,
    String? newModel,
    String? newInspectorId,
    String? newInspectorName,
    String? oldInspectorId,
    DateTime? lastServiceDate,
    DateTime? nextServiceDue,
    required int maxKm,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final vehicleRef = _db.collection(_collectionVehicles).doc(vehicleId);

    try {
      // Get current vehicle to access currentKm if needed
      final vehicleDoc = await vehicleRef.get();
      if (!vehicleDoc.exists) {
        throw Exception(LocaleKeys.vehicle_not_found.tr());
      }

      final vehicleData = vehicleDoc.data()!;
      final currentKmInDb = vehicleData[VehicleFields.currentKm] as int? ?? 0;

      // Build the update map for vehicle
      final Map<String, dynamic> vehicleUpdates = {};

      // 0️⃣ Always update maxKm
      vehicleUpdates[VehicleFields.maxKm] = maxKm;

      // 1️⃣ Handle kilometer changes
      // IMPORTANT: Use newKm if provided, otherwise use current km from database
      final kmToUse = newKm ?? currentKmInDb;

      // Always recalculate remaining and usage when maxKm changes OR when newKm is provided
      if (newKm != null || maxKm != vehicleData[VehicleFields.maxKm]) {
        final remainingKm = maxKm - kmToUse;
        final usagePercent = ((kmToUse / maxKm) * 100).clamp(0, 100).toInt();


        if (newKm != null) {
          vehicleUpdates[VehicleFields.currentKm] = newKm;
        }
        vehicleUpdates[VehicleFields.remainingKm] = remainingKm;
        vehicleUpdates[VehicleFields.usagePercent] = usagePercent;
      }

      // 2️⃣ Handle basic field updates
      if (newPlate != null) {
        vehicleUpdates[VehicleFields.plate] = newPlate;
      }
      if (newModel != null) {
        vehicleUpdates[VehicleFields.model] = newModel;
      }

      // 3️⃣ Handle service date updates
      if (lastServiceDate != null) {
        vehicleUpdates[VehicleFields.lastServiceDate] = Timestamp.fromDate(
          lastServiceDate,
        );
      }
      if (nextServiceDue != null) {
        vehicleUpdates[VehicleFields.nextServiceDue] = Timestamp.fromDate(
          nextServiceDue,
        );
      }

      // 4️⃣ Handle inspector assignment changes
      if (newInspectorId != null) {
        // UNASSIGN
        if (newInspectorId.isEmpty) {
          vehicleUpdates[VehicleFields.assignedInspectorId] = null;
          vehicleUpdates[VehicleFields.assignedInspectorName] = null;
          vehicleUpdates[VehicleFields.status] = AppConstants.available;

          if (oldInspectorId != null && oldInspectorId.isNotEmpty) {
            await _userService.updateInspectorHistoryBatch(
              batch: batch,
              inspectorId: oldInspectorId,
              updates: {
                IHF.vehicleIds: FieldValue.arrayRemove([vehicleId]),
              },
            );
          }
        } else {
          // ASSIGN/REASSIGN
          vehicleUpdates[VehicleFields.assignedInspectorId] = newInspectorId;
          vehicleUpdates[VehicleFields.assignedInspectorName] =
              newInspectorName;
          vehicleUpdates[VehicleFields.status] = AppConstants.assigned;

          if (oldInspectorId != null && oldInspectorId.isNotEmpty) {
            await _userService.updateInspectorHistoryBatch(
              batch: batch,
              inspectorId: oldInspectorId,
              updates: {
                IHF.vehicleIds: FieldValue.arrayRemove([vehicleId]),
              },
            );
          }

          await _userService.updateInspectorHistoryBatch(
            batch: batch,
            inspectorId: newInspectorId,
            updates: {
              IHF.vehicleIds: FieldValue.arrayUnion([vehicleId]),
            },
          );
        }
      }

      // Add updated timestamp
      vehicleUpdates[VehicleFields.updatedAt] = FieldValue.serverTimestamp();

      // 5️⃣ Update vehicle document in batch
      if (vehicleUpdates.isNotEmpty) {
        batch.update(vehicleRef, vehicleUpdates);
      }

      // 6️⃣ Commit the batch (All or Nothing)
      await batch.commit();

      console('✅ Vehicle $vehicleId updated successfully');
    } catch (e, st) {
      print("❌ Error updating vehicle: $e\n$st");
      rethrow;
    }
  }

  Future<void> deleteVehicle({
    required String vehicleId,
    String? inspectorId,
  }) async {
    final batch = _db.batch();
    final vehicleRef = _db.collection(_collectionVehicles).doc(vehicleId);

    try {
      // 1️⃣ Delete vehicle document
      batch.delete(vehicleRef);

      // 2️⃣ If assigned inspector exists, update their history
      if (inspectorId != null && inspectorId.isNotEmpty) {
        final inspectorHistoryRef = _db
            .collection(Collections.inspectorStats)
            .doc(inspectorId);

        batch.update(inspectorHistoryRef, {
          IHF.vehicleIds: FieldValue.arrayRemove([vehicleId]),
          IHF.lastUpdated: Timestamp.now(),
        });
      }

      // 3️⃣ Commit all batched changes together
      await batch.commit();

      console('✅ Vehicle $vehicleId deleted successfully');
      if (inspectorId != null && inspectorId.isNotEmpty) {
        console('🧾 Inspector $inspectorId history updated (vehicle removed)');
      }
    } catch (e, st) {
      print('❌ Error deleting vehicle: $e\n$st');
      rethrow;
    }
  }

  Future<void> createVehicle({
    required String plate,
    required String model,
    required int currentKm,
    required int maxKm,
    required int remainingKm,
    required int usagePercent,
    required DateTime lastServiceDate,
    required DateTime nextServiceDue,
  }) async {
    try {
      await _db.collection(_collectionVehicles).add({
        VehicleFields.plate: plate,
        VehicleFields.model: model,
        VehicleFields.currentKm: currentKm,
        VehicleFields.maxKm: maxKm,
        VehicleFields.remainingKm: remainingKm,
        VehicleFields.usagePercent: usagePercent,
        VehicleFields.lastServiceDate: Timestamp.fromDate(lastServiceDate),
        VehicleFields.nextServiceDue: Timestamp.fromDate(nextServiceDue),
        VehicleFields.status: AppConstants.available,
        VehicleFields.assignedInspector: {
          InspectorFields.id: null,
          InspectorFields.name: null,
        },
        VehicleFields.createdAt: FieldValue.serverTimestamp(),
        VehicleFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating vehicle: $e');
      rethrow;
    }
  }

  Future<List<VehicleModel>> getVehicleByInspector(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(Collections.vehicles)
          .where(VehicleFields.assignedInspectorId, isEqualTo: inspectorId)
          .get();
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting inspector vehicles: $e');
      return [];
    }
  }
}
