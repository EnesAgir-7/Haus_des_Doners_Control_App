import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/widgets/custom_toast.dart';

import '../firebase_services/firebase_vehicle_service.dart';
import '../models/vehicle_model.dart';
import '../translations/locale_keys.g.dart';

class ProviderFleet extends ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();

  VehicleModel? _assignedVehicle;
  List<VehicleModel> _allVehicles = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;

  final TextEditingController kmController = TextEditingController();

  VehicleModel? get assignedVehicle => _assignedVehicle;
  List<VehicleModel> get allVehicles => _allVehicles;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

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

  Future<void> initialize() async {
    await fetchAssignedVehicle();
  }

  Future<void> fetchAssignedVehicle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _assignedVehicle = await _vehicleService.getVehicleByInspector(
        loggedInUser!.id,
      );

      if (_assignedVehicle != null) {
        kmController.text = _assignedVehicle!.currentKm.toString();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage =
          '${LocaleKeys.error_loading_vehicle.tr(args: [e.toString()])}';
      _isLoading = false;
      notifyListeners();
      print(_errorMessage);
    }
  }

  void initializeWithStreams() {
    _vehicleService.streamVehicleByInspector(loggedInUser!.id).listen((
      vehicle,
    ) {
      _assignedVehicle = vehicle;
      if (vehicle != null) {
        kmController.text = vehicle.currentKm.toString();
      }
      notifyListeners();
    });
  }

  Future<bool> updateVehicleKm(int newKm, BuildContext context) async {
    if (_assignedVehicle == null) {
      _errorMessage = LocaleKeys.no_vehicle_assigned.tr();
      notifyListeners();
      return false;
    }

    if (newKm < _assignedVehicle!.currentKm) {
      _errorMessage = LocaleKeys.km_less_than_current.tr();
      showSnakBarr(context, LocaleKeys.km_less_than_current.tr());
      return false;
    }

    if (newKm > _assignedVehicle!.maxKm) {
      showSnakBarr(context, LocaleKeys.km_exceeds_limit.tr());
      return false;
    }

    try {
      _isUpdating = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      await _vehicleService.updateVehicleKm(_assignedVehicle!.id, newKm);

      _successMessage = LocaleKeys.km_update_success.tr();
      _isUpdating = false;
      if (_successMessage != null)
        showSnakBarr(context, _successMessage.toString());
      notifyListeners();

      await fetchAssignedVehicle();

      _successMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = '${LocaleKeys.km_update_error.tr(args: [e.toString()])}';
      _isUpdating = false;
      notifyListeners();
      print(_errorMessage);
      return false;
    }
  }

  Future updateKmFromController(BuildContext context) async {
    final kmText = kmController.text.trim();
    if (kmText.isEmpty) {
      showSnakBarr(context, LocaleKeys.enter_km.tr());
      return false;
    }

    final newKm = int.tryParse(kmText);
    if (newKm == null) {
      showSnakBarr(context, LocaleKeys.invalid_km_value.tr());
      return false;
    }

    if (context.mounted) Navigator.pop(context);
    await updateVehicleKm(newKm, context);
  }

  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final allVehicles = await _vehicleService.getAllVehicles();
      return allVehicles.firstWhere(
        (v) => v.id == vehicleId,
        orElse: () => throw Exception(LocaleKeys.vehicle_not_found.tr()),
      );
    } catch (e) {
      print('Error getting vehicle by ID: $e');
      return null;
    }
  }

  List<VehicleModel> get vehiclesNeedingService {
    return _allVehicles.where((v) => v.isServiceDueSoon).toList();
  }

  List<VehicleModel> getVehiclesByStatus(String status) {
    return _allVehicles.where((v) => v.status == status).toList();
  }

  Future<void> refresh() async {
    await fetchAssignedVehicle();
  }

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
