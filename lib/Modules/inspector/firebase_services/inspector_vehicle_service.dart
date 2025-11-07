import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/common_services/notification_helper.dart';

import '../../../core/console.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/vehicle_model.dart';
import '../../../translations/locale_keys.g.dart';

class InspectorVehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionVehicles = Collections.vehicles;

  // Get vehicle assigned to inspector
  Stream<List<VehicleModel>> streamVehiclesByInspector(String inspectorId) {
    return _db
        .collection(_collectionVehicles)
        .where(VehicleFields.assignedInspectorId, isEqualTo: inspectorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VehicleModel.fromFirestore(doc))
              .toList(),
        );
  }

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

  // Update vehicle kilometers
  // Fixed Inspector updateVehicleKm method for InspectorVehicleService

  Future<void> updateVehicleKm(String vehicleId, int newKm) async {
    try {
      final vehicleRef = _db.collection(_collectionVehicles).doc(vehicleId);

      // Get current vehicle data
      final vehicleDoc = await vehicleRef.get();
      if (!vehicleDoc.exists) {
        throw Exception(LocaleKeys.vehicle_not_found.tr());
      }

      final vehicleData = vehicleDoc.data()!;
      final maxKm = vehicleData[VehicleFields.maxKm] as int? ?? 0;
      final currentKmInDb = vehicleData[VehicleFields.currentKm] as int? ?? 0;

      // Validate: new KM should be >= current (allow same value)
      if (newKm < currentKmInDb) {
        throw Exception(LocaleKeys.km_less_than_current.tr());
      }

      // Validate: new KM should not exceed max
      if (newKm > maxKm) {
        throw Exception(LocaleKeys.km_exceeds_limit.tr());
      }

      // Calculate new remaining values
      final remainingKm = maxKm - newKm;
      final remainingPercent = maxKm > 0
          ? ((remainingKm / maxKm) * 100).clamp(0, 100).toInt()
          : 0;

      // Update vehicle in Firestore - CRITICAL OPERATION
      await vehicleRef.update({
        VehicleFields.currentKm: newKm,
        VehicleFields.remainingKm: remainingKm,
        VehicleFields.remainingPercent: remainingPercent,
        VehicleFields.updatedAt: FieldValue.serverTimestamp(),
      });

      console('✅ Vehicle $vehicleId kilometers updated to $newKm km');

      // Send notification to all admins AFTER successful update (non-blocking)
      _sendVehicleKmNotificationToAdmins(
        vehicleId: vehicleId,
        newKm: newKm,
        remainingKm: remainingKm,
      ).catchError((error) {
        console('⚠️ Failed to send vehicle KM notification: $error');
        // Silently fail - don't affect the main operation
      });
    } catch (e, st) {
      console(
        '❌ Error updating vehicle kilometers: $e\n$st',
        type: DebugType.error,
      );
      rethrow;
    }
  }

  // Separate method for sending notifications (non-blocking)
  Future<void> _sendVehicleKmNotificationToAdmins({
    required String vehicleId,
    required int newKm,
    required int remainingKm,
  }) async {
    try {
      await NotificationHelper.instance.sendNotificationToTopic(
        topic: AppConstants.adminTopic,
        title: LocaleKeys.vehicle_km_updated_title.tr(),
        body: LocaleKeys.vehicle_km_updated_body.tr(
          namedArgs: {
            'newKm': newKm.toString(),
            'remainingKm': remainingKm.toString(),
          },
        ),
        data: {
          'type': 'vehicle_km_updated',
          'vehicleId': vehicleId,
          'newKm': newKm,
          'remainingKm': remainingKm,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      console('⚠️ Notification error: $e');
      // Don't rethrow - this is intentionally silent
    }
  }
}
