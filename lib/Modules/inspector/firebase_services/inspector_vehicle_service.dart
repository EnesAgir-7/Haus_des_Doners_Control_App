import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../models/vehicle_model.dart';

class InspectorVehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionVehicles = Collections.vehicles;

  // Get vehicle assigned to inspector
  Future<VehicleModel?> getVehicleByInspector(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collectionVehicles)
          .where('assignedInspectorId', isEqualTo: inspectorId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return VehicleModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting vehicle by inspector: $e');
      return null;
    }
  }

  // Stream vehicle by inspector (real-time)
  Stream<VehicleModel?> streamVehicleByInspector(String inspectorId) {
    return _db
        .collection(_collectionVehicles)
        .where('assignedInspectorId', isEqualTo: inspectorId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return VehicleModel.fromFirestore(snapshot.docs.first);
        });
  }

  // Get all vehicles (admin)
  Future<List<VehicleModel>> getAllVehicles() async {
    try {
      final snapshot = await _db
          .collection(_collectionVehicles)
          .orderBy('plate')
          .get();

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

  // Assign vehicle to inspector
  Future<void> assignVehicleToInspector(
    String vehicleId,
    String inspectorId,
    String inspectorName,
  ) async {
    try {
      // First, find if inspector has any assigned vehicle
      final currentVehicle = await _db
          .collection(_collectionVehicles)
          .where('assignedInspectorId', isEqualTo: inspectorId)
          .get();

      // If inspector has a vehicle, unassign it
      if (currentVehicle.docs.isNotEmpty) {
        await _db
            .collection(_collectionVehicles)
            .doc(currentVehicle.docs.first.id)
            .update({
              'assignedInspectorId': null,
              'assignedInspectorName': null,
              'status': 'available',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      // Assign new vehicle to inspector
      await _db.collection(_collectionVehicles).doc(vehicleId).update({
        'assignedInspectorId': inspectorId,
        'assignedInspectorName': inspectorName,
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error assigning vehicle: $e');
      rethrow;
    }
  }

  // Unassign vehicle
  Future<void> unassignVehicle(String vehicleId) async {
    try {
      await _db.collection(_collectionVehicles).doc(vehicleId).update({
        'assignedInspectorId': null,
        'assignedInspectorName': null,
        'status': 'available',
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
    required String status,
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
        'status': status,
        'assignedInspectorId': null,
        'assignedInspectorName': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating vehicle: $e');
      rethrow;
    }
  }

  Future<void> updateVehicleStatus(String vehicleId, String status) async {
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
}
