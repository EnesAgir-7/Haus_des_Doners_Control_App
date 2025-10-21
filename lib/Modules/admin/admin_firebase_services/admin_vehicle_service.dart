import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../models/vehicle_model.dart';

class AdminVehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionVehicles = Collections.vehicles;

  // Stream vehicle by inspector (real-time)
  Stream<List<VehicleModel>?> streamVehicleByInspector(String inspectorId) {
    return _db
        .collection(_collectionVehicles)
        .where('assignedInspector.id', isEqualTo: inspectorId)
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
          .where('status', isEqualTo: status)
          .get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting vehicles by status: $e');
      return [];
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
      final maxKm = data['maxKm'] as int;
      final remainingKm = maxKm - newKm;
      final usagePercent = ((newKm / maxKm) * 100).round();

      await _db.collection(_collectionVehicles).doc(vehicleId).update({
        'currentKm': newKm,
        'remainingKm': remainingKm,
        'usagePercent': usagePercent,
        'updatedAt': FieldValue.serverTimestamp(),
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
        'assignedInspector.id': inspectorId,
        'assignedInspector.name': inspectorName,
        'status': AppConstants.assigned,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error assigning vehicle: $e');
      rethrow;
    }
  }

  Future<void> unassignVehicle(String vehicleId) async {
    try {
      await _db.collection(_collectionVehicles).doc(vehicleId).update({
        'assignedInspector.id': null,
        'assignedInspector.name': null,
        'status': AppConstants.available,
        'updatedAt': FieldValue.serverTimestamp(),
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
        'plate': plate,
        'model': model,
        'currentKm': currentKm,
        'maxKm': maxKm,
        'remainingKm': remainingKm,
        'usagePercent': usagePercent,
        'lastServiceDate': Timestamp.fromDate(lastServiceDate),
        'nextServiceDue': Timestamp.fromDate(nextServiceDue),
        'status': AppConstants.available,
        'assignedInspector': {'id': null, 'name': null},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating vehicle: $e');
      rethrow;
    }
  }

  Future<void> updatedVehicleStatus(String vehicleId, String status) async {
    try {
      await _db.collection(_collectionVehicles).doc(vehicleId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
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
          .where('assignedInspector.id', isEqualTo: inspectorId)
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
