import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vehicle_model.dart';

class VehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'vehicles';

  // Get vehicle assigned to inspector
  Future<VehicleModel?> getVehicleByInspector(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
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
        .collection(_collection)
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
      final snapshot = await _db.collection(_collection).orderBy('plate').get();

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
          .collection(_collection)
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
      final vehicle = await _db.collection(_collection).doc(vehicleId).get();
      if (!vehicle.exists) throw Exception('Vehicle not found');

      final data = vehicle.data() as Map<String, dynamic>;
      final maxKm = data['maxKm'] as int;
      final remainingKm = maxKm - newKm;
      final usagePercent = ((newKm / maxKm) * 100).round();

      await _db.collection(_collection).doc(vehicleId).update({
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
      await _db.collection(_collection).doc(vehicleId).update({
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
      await _db.collection(_collection).doc(vehicleId).update({
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
}
