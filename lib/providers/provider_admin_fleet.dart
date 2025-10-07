import 'package:flutter/material.dart';
import '../firebase_services/firebase_vehicle_service.dart';
import '../models/vehicle_model.dart';

class ProviderAdminFleet extends ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();

  List<VehicleModel> _vehicles = [];
  List<VehicleModel> get vehicles => _filterVehicles();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  List<VehicleModel> _filterVehicles() {
    if (_searchQuery.isEmpty) return _vehicles;
    return _vehicles.where((vehicle) {
      return vehicle.plate.toLowerCase().contains(_searchQuery) ||
          vehicle.model.toLowerCase().contains(_searchQuery) ||
          vehicle.assignedInspectorName?.toLowerCase().contains(_searchQuery) ==
              true;
    }).toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicles = await _vehicleService.getAllVehicles();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> assignInspector(
    String vehicleId,
    String inspectorId,
    String inspectorName,
  ) async {
    try {
      await _vehicleService.assignVehicleToInspector(
        vehicleId,
        inspectorId,
        inspectorName,
      );
      await loadData(); // Refresh data after assignment
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> unassignInspector(String vehicleId) async {
    try {
      await _vehicleService.unassignVehicle(vehicleId);
      await loadData(); // Refresh data after unassignment
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateVehicleKilometers(String vehicleId, int newKm) async {
    try {
      await _vehicleService.updateVehicleKm(vehicleId, newKm);
      await loadData(); // Refresh data after update
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
