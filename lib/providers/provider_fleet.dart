// lib/providers/fleet_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_services/firebase_user_service.dart';
import '../firebase_services/firebase_vehicle_service.dart';
import '../models/vehicle_model.dart';
import '../models/user_model.dart';

/// Provider for Fleet (File) screen
/// Shows assigned vehicle details and allows KM updates
class ProviderFleet extends ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();
  final UserService _userService = UserService();

  // State
  VehicleModel? _assignedVehicle;
  List<VehicleModel> _allVehicles = []; // For admin view
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;

  // For KM update
  final TextEditingController kmController = TextEditingController();

  // Getters
  VehicleModel? get assignedVehicle => _assignedVehicle;
  List<VehicleModel> get allVehicles => _allVehicles;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Computed values for assigned vehicle
  bool get hasAssignedVehicle => _assignedVehicle != null;
  String get vehiclePlate => _assignedVehicle?.plate ?? 'N/A';
  String get vehicleModel => _assignedVehicle?.model ?? 'N/A';
  int get currentKm => _assignedVehicle?.currentKm ?? 0;
  int get maxKm => _assignedVehicle?.maxKm ?? 0;
  int get remainingKm => _assignedVehicle?.remainingKm ?? 0;
  int get usagePercent => _assignedVehicle?.usagePercent ?? 0;
  bool get isServiceDueSoon => _assignedVehicle?.isServiceDueSoon ?? false;
  String get serviceDueText => _assignedVehicle?.serviceDueText ?? '';
  String get kmProgressColor => _assignedVehicle?.kmProgressColor ?? 'green';

  // Initialize for inspector
  Future<void> initialize() async {
    await fetchAssignedVehicle();
  }

  // Initialize for admin
  Future<void> initializeAdmin() async {
    await fetchAllVehicles();
  }

  // Fetch assigned vehicle for current inspector
  Future<void> fetchAssignedVehicle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current user
      _currentUser = await _userService.getUserById(userId);

      // Get assigned vehicle
      _assignedVehicle = await _vehicleService.getVehicleByInspector(userId);

      // Set current KM in controller
      if (_assignedVehicle != null) {
        kmController.text = _assignedVehicle!.currentKm.toString();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading vehicle: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_errorMessage);
    }
  }

  // Stream-based initialization (real-time updates)
  void initializeWithStreams() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _vehicleService.streamVehicleByInspector(userId).listen((vehicle) {
      _assignedVehicle = vehicle;
      if (vehicle != null) {
        kmController.text = vehicle.currentKm.toString();
      }
      notifyListeners();
    });
  }

  // Fetch all vehicles (admin only)
  Future<void> fetchAllVehicles() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _allVehicles = await _vehicleService.getAllVehicles();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading vehicles: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_errorMessage);
    }
  }

  // Update vehicle kilometers
  Future<bool> updateVehicleKm(int newKm) async {
    if (_assignedVehicle == null) {
      _errorMessage = 'No vehicle assigned';
      notifyListeners();
      return false;
    }

    if (newKm < _assignedVehicle!.currentKm) {
      _errorMessage = 'Yeni kilometre mevcut kilometreden küçük olamaz';
      notifyListeners();
      return false;
    }

    if (newKm > _assignedVehicle!.maxKm) {
      _errorMessage =
          'Kilometre limiti aşıldı. Lütfen servis ile iletişime geçin';
      notifyListeners();
      return false;
    }

    try {
      _isUpdating = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      await _vehicleService.updateVehicleKm(_assignedVehicle!.id, newKm);

      _successMessage = 'Kilometre başarıyla güncellendi';
      _isUpdating = false;
      notifyListeners();

      // Refresh vehicle data
      await fetchAssignedVehicle();

      // Clear success message after 3 seconds
      await Future.delayed(Duration(seconds: 3));
      _successMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Kilometre güncellenirken hata oluştu: ${e.toString()}';
      _isUpdating = false;
      notifyListeners();
      print(_errorMessage);
      return false;
    }
  }

  // Update KM from controller
  Future<bool> updateKmFromController() async {
    final kmText = kmController.text.trim();
    if (kmText.isEmpty) {
      _errorMessage = 'Lütfen kilometre giriniz';
      notifyListeners();
      return false;
    }

    final newKm = int.tryParse(kmText);
    if (newKm == null) {
      _errorMessage = 'Geçersiz kilometre değeri';
      notifyListeners();
      return false;
    }

    return await updateVehicleKm(newKm);
  }

  // Get vehicle by ID (for detail view)
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final allVehicles = await _vehicleService.getAllVehicles();
      return allVehicles.firstWhere(
        (v) => v.id == vehicleId,
        orElse: () => throw Exception('Vehicle not found'),
      );
    } catch (e) {
      print('Error getting vehicle by ID: $e');
      return null;
    }
  }

  // Get vehicles needing service soon
  List<VehicleModel> get vehiclesNeedingService {
    return _allVehicles.where((v) => v.isServiceDueSoon).toList();
  }

  // Get vehicles by status
  List<VehicleModel> getVehiclesByStatus(String status) {
    return _allVehicles.where((v) => v.status == status).toList();
  }

  // Assign vehicle to inspector (admin only)
  Future<bool> assignVehicle(
    String vehicleId,
    String inspectorId,
    String inspectorName,
  ) async {
    try {
      _isUpdating = true;
      _errorMessage = null;
      notifyListeners();

      await _vehicleService.assignVehicleToInspector(
        vehicleId,
        inspectorId,
        inspectorName,
      );

      _successMessage = 'Araç başarıyla atandı';
      _isUpdating = false;
      notifyListeners();

      await fetchAllVehicles();
      return true;
    } catch (e) {
      _errorMessage = 'Araç atanırken hata oluştu: ${e.toString()}';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  // Unassign vehicle (admin only)
  Future<bool> unassignVehicle(String vehicleId) async {
    try {
      _isUpdating = true;
      _errorMessage = null;
      notifyListeners();

      await _vehicleService.unassignVehicle(vehicleId);

      _successMessage = 'Araç ataması kaldırıldı';
      _isUpdating = false;
      notifyListeners();

      await fetchAllVehicles();
      return true;
    } catch (e) {
      _errorMessage = 'Araç ataması kaldırılırken hata oluştu: ${e.toString()}';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh
  Future<void> refresh() async {
    if (_currentUser?.isAdmin ?? false) {
      await fetchAllVehicles();
    } else {
      await fetchAssignedVehicle();
    }
  }

  // Clear messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    kmController.dispose();
    super.dispose();
  }
}
