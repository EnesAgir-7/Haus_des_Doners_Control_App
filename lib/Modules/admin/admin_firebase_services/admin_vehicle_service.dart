import 'package:cloud_firestore/cloud_firestore.dart';

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
  Stream<List<VehicleModel>?> streamVehicleByInspector(String inspectorId) {
    return _db
        .collection(_collectionVehicles)
        .where(VehicleFields.assignedInspectorId, isEqualTo: inspectorId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return snapshot.docs
              .map((doc) => VehicleModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get all vehicles (admin)
  Future<List<VehicleModel>> getAllVehicles() async {
    try {
      final snapshot = await _db.collection(_collectionVehicles).get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all vehicles: $e');
      return [];
    }
  }

  // Get vehicles by status
  Future<List<VehicleModel>> getVehiclesByStatus(String status) async {
    try {
      final snapshot = await _db
          .collection(_collectionVehicles)
          .where(VehicleFields.status, isEqualTo: status)
          .get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting vehicles by status: $e');
      return [];
    }
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
      // Build the update map for vehicle
      final Map<String, dynamic> vehicleUpdates = {};

      // 1️⃣ Handle kilometer changes
      if (newKm != null) {
        final remainingKm = maxKm - newKm;
        final usagePercent = ((newKm / maxKm) * 100).round();

        vehicleUpdates[VehicleFields.currentKm] = newKm;
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
      // newInspectorId will be passed ONLY if inspector changed
      if (newInspectorId != null) {
        console("Inspector id not null");
        // Check if unassigning (empty string means unassign)
        if (newInspectorId.isEmpty) {
          console("Inspector id empty");
          // UNASSIGNING
          vehicleUpdates[VehicleFields.assignedInspectorId] = null;
          vehicleUpdates[VehicleFields.assignedInspectorName] = null;
          vehicleUpdates[VehicleFields.status] = AppConstants.available;

          // Remove from old inspector's history
          if (oldInspectorId != null && oldInspectorId.isNotEmpty) {
            console("Old inspector is not empty or null");
            await _userService.updateInspectorHistoryBatch(
              batch: batch,
              inspectorId: oldInspectorId,
              updates: {
                IHF.vehicleIds: FieldValue.arrayRemove([vehicleId]),
              },
            );
          }
        } else {
          console("New inspector is not empty");
          // ASSIGNING OR REASSIGNING
          vehicleUpdates[VehicleFields.assignedInspectorId] = newInspectorId;
          vehicleUpdates[VehicleFields.assignedInspectorName] =
              newInspectorName;
          vehicleUpdates[VehicleFields.status] = AppConstants.assigned;

          // Remove from old inspector's history (if exists)
          if (oldInspectorId != null && oldInspectorId.isNotEmpty) {
            console("Old inspector is not empty or null");
            await _userService.updateInspectorHistoryBatch(
              batch: batch,
              inspectorId: oldInspectorId,
              updates: {
                IHF.vehicleIds: FieldValue.arrayRemove([vehicleId]),
              },
            );
          }

          // Add to new inspector's history
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

  // Update vehicle kilometers
  Future<void> updateVehicleKm(String vehicleId, int newKm) async {
    try {
      final vehicle = await _db
          .collection(_collectionVehicles)
          .doc(vehicleId)
          .get();
      if (!vehicle.exists) throw Exception('Vehicle not found');

      final data = vehicle.data() as Map<String, dynamic>;
      final maxKm = data[VehicleFields.maxKm] as int;
      final remainingKm = maxKm - newKm;
      final usagePercent = ((newKm / maxKm) * 100).round();

      await _db.collection(_collectionVehicles).doc(vehicleId).update({
        VehicleFields.currentKm: newKm,
        VehicleFields.remainingKm: remainingKm,
        VehicleFields.usagePercent: usagePercent,
        VehicleFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating vehicle KM: $e');
      rethrow;
    }
  }

  // Get vehicle by ID
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final doc = await _db
          .collection(Collections.vehicles)
          .doc(vehicleId)
          .get();
      if (!doc.exists) return null;
      return VehicleModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting vehicle: $e');
      return null;
    }
  }

  // Assign vehicle to inspector
  Future<void> assignVehicleToInspector(
    String vehicleId,
    String inspectorId,
    String inspectorName,
  ) async {
    try {
      await _db.collection(_collectionVehicles).doc(vehicleId).update({
        VehicleFields.assignedInspectorId: inspectorId,
        VehicleFields.assignedInspectorName: inspectorName,
        VehicleFields.status: AppConstants.assigned,
        VehicleFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error assigning vehicle: $e');
      rethrow;
    }
  }

  Future<void> unassignVehicle(String vehicleId) async {
    try {
      await _db.collection(_collectionVehicles).doc(vehicleId).update({
        VehicleFields.assignedInspectorId: null,
        VehicleFields.assignedInspectorName: null,
        VehicleFields.status: AppConstants.available,
        VehicleFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error unassigning vehicle: $e');
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

  Future<void> updatedVehicleStatus(String vehicleId, String status) async {
    try {
      await _db.collection(_collectionVehicles).doc(vehicleId).update({
        VehicleFields.status: status,
        VehicleFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating vehicle status: $e');
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
