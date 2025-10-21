import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../models/vehicle_model.dart';

class InspectorVehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionVehicles = Collections.vehicles;

  // Get vehicle assigned to inspector
  Future<List<VehicleModel>> getVehiclesByInspector(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collectionVehicles)
          .where('assignedInspector.id', isEqualTo: inspectorId)
          .get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting vehicles by inspector: $e');
      return [];
    }
  }

  // Stream vehicle by inspector (real-time)
  Stream<List<VehicleModel>?> streamVehicleByInspector(String inspectorId) {
    return _db
        .collection(_collectionVehicles)
        .where('assignedInspectorId', isEqualTo: inspectorId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return snapshot.docs
              .map((doc) => VehicleModel.fromFirestore(doc))
              .toList();
        });
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
}
