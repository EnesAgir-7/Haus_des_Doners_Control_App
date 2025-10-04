import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';
import '../models/vehicle_model.dart'; // Make sure you have this model

class VehicleService {
  final CollectionReference _vehiclesCollection = FirebaseFirestore.instance
      .collection(Collections.vehicles);

  /// Fetches a single vehicle assigned to a specific inspector.
  Future<VehicleModel?> getVehicleByInspector(String inspectorId) async {
    try {
      final querySnapshot = await _vehiclesCollection
          .where('assignedInspectorId', isEqualTo: inspectorId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      return VehicleModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting vehicle by inspector: $e');
      rethrow;
    }
  }

  /// Fetches all vehicles from the collection.
  Future<List<VehicleModel>> getAllVehicles() async {
    try {
      final snapshot = await _vehiclesCollection.get();
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all vehicles: $e');
      rethrow;
    }
  }

  /// Updates the kilometers for a specific vehicle.
  Future<void> updateVehicleKm(String vehicleId, int newKm) async {
    try {
      final vehicleDoc = await _vehiclesCollection.doc(vehicleId).get();
      if (!vehicleDoc.exists) {
        throw Exception('Vehicle not found');
      }
      final vehicle = VehicleModel.fromFirestore(vehicleDoc);
      final maxKm = vehicle.maxKm;

      // Recalculate derived fields
      final remainingKm = maxKm - newKm;
      final usagePercent = (newKm / maxKm * 100).round();

      await _vehiclesCollection.doc(vehicleId).update({
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

  // --- Other methods required by your provider ---

  Stream<VehicleModel?> streamVehicleByInspector(String inspectorId) {
    return _vehiclesCollection
        .where('assignedInspectorId', isEqualTo: inspectorId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return VehicleModel.fromFirestore(snapshot.docs.first);
        });
  }

  Future<void> assignVehicleToInspector(
    String vehicleId,
    String inspectorId,
    String inspectorName,
  ) async {
    await _vehiclesCollection.doc(vehicleId).update({
      'assignedInspectorId': inspectorId,
      'assignedInspectorName': inspectorName,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unassignVehicle(String vehicleId) async {
    await _vehiclesCollection.doc(vehicleId).update({
      'assignedInspectorId': null,
      'assignedInspectorName': null,
      'status': 'available',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
