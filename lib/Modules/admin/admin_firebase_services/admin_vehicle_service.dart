import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';

import '../../../common_services/notification_helper.dart';
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
    required BuildContext context,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final vehicleRef = _db.collection(_collectionVehicles).doc(vehicleId);

    try {
      // Get current vehicle
      final vehicleDoc = await vehicleRef.get();
      if (!vehicleDoc.exists) {
        throw Exception(LocaleKeys.vehicle_not_found.tr());
      }

      final vehicleData = vehicleDoc.data()!;
      final currentKmInDb = vehicleData[VehicleFields.currentKm] as int? ?? 0;

      // Build update map
      final Map<String, dynamic> vehicleUpdates = {};

      // Update maxKm
      vehicleUpdates[VehicleFields.maxKm] = maxKm;

      // Handle kilometer changes
      final kmToUse = newKm ?? currentKmInDb;
      final remainingKm = maxKm - kmToUse;
      final remainingPercent = ((remainingKm / maxKm) * 100)
          .clamp(0, 100)
          .toInt();

      if (newKm != null) {
        vehicleUpdates[VehicleFields.currentKm] = newKm;
      }
      vehicleUpdates[VehicleFields.remainingKm] = remainingKm;
      vehicleUpdates[VehicleFields.remainingPercent] = remainingPercent;

      // Other updates
      if (newPlate != null) vehicleUpdates[VehicleFields.plate] = newPlate;
      if (newModel != null) vehicleUpdates[VehicleFields.model] = newModel;
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

      // Track inspector change for notifications
      bool inspectorChanged = false;
      String? notifyInspectorId;

      // Handle inspector assignment
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
            inspectorChanged = true;
            notifyInspectorId = oldInspectorId;
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
          inspectorChanged = true;
          notifyInspectorId = newInspectorId;
        }
      }

      // Updated timestamp
      vehicleUpdates[VehicleFields.updatedAt] = FieldValue.serverTimestamp();

      // Update vehicle
      if (vehicleUpdates.isNotEmpty) {
        batch.update(vehicleRef, vehicleUpdates);
      }

      // Commit batch
      await batch.commit();
      console('✅ Vehicle $vehicleId updated successfully');

      // ✅ Send notification (if newKm updated or inspector changed)
      // Determine which inspector to notify
      final inspectorToNotify =
          notifyInspectorId ??
          (oldInspectorId?.isNotEmpty == true ? oldInspectorId : null);

      if (inspectorToNotify != null && inspectorToNotify.isNotEmpty) {
        await NotificationHelper.instance.sendToInspector(
          inspectorId: inspectorToNotify,
          context: context,
          title: LocaleKeys.vehicle_km_updated_title.tr(),
          body: LocaleKeys.vehicle_km_updated_body.tr(
            namedArgs: {
              'vehicleId': vehicleId,
              'newKm': kmToUse.toString(),
              'remainingKm': remainingKm.toString(),
            },
          ),
          data: {
            'type': 'vehicle_km_updated',
            'vehicleId': vehicleId,
            'newKm': kmToUse,
            'remainingKm': remainingKm,
            'inspectorChanged': inspectorChanged,
          },
        );
      }
    } catch (e, st) {
      console('❌ Error updating vehicle: $e\n$st', type: DebugType.error);
      rethrow;
    }
  }

  Future<void> deleteVehicle({
    required String vehicleId,
    String? inspectorId,
    required BuildContext context,
  }) async {
    final batch = _db.batch();
    final vehicleRef = _db.collection(_collectionVehicles).doc(vehicleId);

    try {
      // 1️⃣ Delete vehicle document
      batch.delete(vehicleRef);

      // 2️⃣ Update inspector history if assigned
      if (inspectorId != null && inspectorId.isNotEmpty) {
        await _userService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: inspectorId,
          updates: {
            IHF.vehicleIds: FieldValue.arrayRemove([vehicleId]),
          },
        );
      }

      // 3️⃣ Commit batch
      await batch.commit();

      console('✅ Vehicle $vehicleId deleted successfully');

      // 4️⃣ Send notification to inspector
      if (inspectorId != null && inspectorId.isNotEmpty) {
        console('🧾 Inspector $inspectorId history updated (vehicle removed)');

        await NotificationHelper.instance.sendToInspector(
          inspectorId: inspectorId,
          context: context,
          title: LocaleKeys.vehicle_deleted_title.tr(),
          body: LocaleKeys.vehicle_deleted_body.tr(
            namedArgs: {'vehicleId': vehicleId},
          ),
          data: {'type': 'vehicle_deleted', 'vehicleId': vehicleId},
        );
      }
    } catch (e, st) {
      console('❌ Error deleting vehicle: $e\n$st', type: DebugType.error);
      rethrow;
    }
  }

  Future<void> createVehicle({
    required String plate,
    required String model,
    required int currentKm,
    required int maxKm,
    required int remainingKm,
    required int remainingPercent,
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
        VehicleFields.remainingPercent: remainingPercent,
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
