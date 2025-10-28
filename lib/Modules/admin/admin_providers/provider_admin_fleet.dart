import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';

import '../../../core/console.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/vehicle_model.dart';
import '../admin_firebase_services/admin_vehicle_service.dart';

class ProviderAdminVehicles extends ChangeNotifier {
  final AdminVehicleService _vehicleService = AdminVehicleService();

  List<VehicleModel> _vehicles = [];
  List<VehicleModel> get vehicles => _filterVehicles();

  StreamSubscription<List<VehicleModel>>? _vehiclesSubscription;
  String? _currentInspectorId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';

  Future<void> initialize() async {
    await initializeVehicleStream();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  List<VehicleModel> _filterVehicles() {
    if (_searchQuery.isEmpty) return _vehicles;
    return _vehicles.where((vehicle) {
      return vehicle.plate.toLowerCase().contains(_searchQuery) ||
          vehicle.model.toLowerCase().contains(_searchQuery) ||
          vehicle.assignedInspector?.name.toLowerCase().contains(
                _searchQuery,
              ) ==
              true;
    }).toList();
  }

  initializeVehicleStream() {
    final inspectorId = loggedInUser!.id;

    if (_vehiclesSubscription != null && _currentInspectorId == inspectorId) {
      console("Same user and stream is On");
      return;
    }
    _currentInspectorId = inspectorId;
    _vehiclesSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

     try {
      _vehiclesSubscription = _vehicleService
          .streamAllVehicles()
          .listen(
            (tasks) {
              _vehicles = tasks;
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
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
    try {
      await _vehicleService.updateVehicleWithBatch(
        vehicleId: vehicleId,
        newKm: newKm,
        newPlate: newPlate,
        newModel: newModel,
        newInspectorId: newInspectorId,
        newInspectorName: newInspectorName,
        oldInspectorId: oldInspectorId,
        lastServiceDate: lastServiceDate,
        nextServiceDue: nextServiceDue,
        maxKm: maxKm,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
      await _vehicleService.createVehicle(
        plate: plate,
        model: model,
        currentKm: currentKm,
        maxKm: maxKm,
        remainingKm: remainingKm,
        usagePercent: usagePercent,
        lastServiceDate: lastServiceDate,
        nextServiceDue: nextServiceDue,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e; // Re-throw to show error in UI
    }
  }

  Future<void> deleteVehicle({
    required String vehicleId,
    String? inspectorId,
    String? inspectorName,
    required BuildContext context,
  }) async {
    try {
      await _vehicleService.deleteVehicle(
        vehicleId: vehicleId,
        inspectorId: inspectorId,
      );

      if (context.mounted) {
        final msg = (inspectorId != null && inspectorId.isNotEmpty)
            ? '✅ Vehicle deleted successfully and unassigned from inspector "$inspectorName".'
            : '✅ Vehicle deleted successfully';

        showSnakBarr(context, msg);

        await Future.delayed(const Duration(milliseconds: 400));
        Navigator.pop(context);
      }
    } catch (e) {
      _error = 'Error deleting vehicle: $e';
      if (context.mounted) {
        showSnakBarr(context, '❌ $_error');
      }
    }
  }
}
