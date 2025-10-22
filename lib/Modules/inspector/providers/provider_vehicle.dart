import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../models/vehicle_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../firebase_services/inspector_vehicle_service.dart';

class ProviderVehicle extends ChangeNotifier {
  final InspectorVehicleService _vehicleService = InspectorVehicleService();

  VehicleModel? _assignedVehiclee;
  List<VehicleModel> _vehicles = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;
  // Getters for state
  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoadingg => _isLoading;
  int get vehicleCount => _vehicles.length;

  final TextEditingController kmController = TextEditingController();

  VehicleModel? get assignedVehicle => _assignedVehiclee;
  bool get isUpdatingg => _isUpdating;
  String? get errorMessagee => _errorMessage;
  String? get successMessagee => _successMessage;

  bool get hasAssignedVehicle => _assignedVehiclee != null;
  String get vehiclePlate => _assignedVehiclee?.plate ?? 'N/A';
  String get vehicleModel => _assignedVehiclee?.model ?? 'N/A';
  int get currentKm => _assignedVehiclee?.currentKm ?? 0;
  int get maxKm => _assignedVehiclee?.maxKm ?? 0;
  int get remainingKm => _assignedVehiclee?.remainingKm ?? 0;
  int get usagePercent => _assignedVehiclee?.usagePercent ?? 0;
  bool get isServiceDueSoon => _assignedVehiclee?.isServiceDueSoon ?? false;
  String get serviceDueText => _assignedVehiclee?.serviceDueText ?? '';
  String get kmProgressColor => _assignedVehiclee?.kmProgressColor ?? 'green';

  Future<void> initialize() async {
    await fetchInspectorVehicles();
  }

  setSelectedVehicle(VehicleModel vehicle) {
    _assignedVehiclee = vehicle;
    kmController.text = vehicle.currentKm.toString();
    notifyListeners();
  }

  Future<void> fetchInspectorVehicles() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _vehicles = await _vehicleService.getVehiclesByInspector(
        loggedInUser!.id,
      );
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


  Future<bool> updateVehicleKm(int newKm, BuildContext context) async {
    if (_assignedVehiclee == null) {
      showSnakBarr(context, LocaleKeys.no_vehicle_assigned.tr());
      notifyListeners();
      return false;
    }

    if (newKm < _assignedVehiclee!.currentKm) {
      showSnakBarr(context, LocaleKeys.km_less_than_current.tr());
      return false;
    }

    if (newKm > _assignedVehiclee!.maxKm) {
      showSnakBarr(context, LocaleKeys.km_exceeds_limit.tr());
      return false;
    }

    try {
      _isUpdating = true;
      notifyListeners();

      await _vehicleService.updateVehicleKm(_assignedVehiclee!.id, newKm);

      final updatedRemainingKm = _assignedVehiclee!.maxKm - newKm;
      final updatedUsagePercent = ((newKm / _assignedVehiclee!.maxKm) * 100)
          .clamp(0, 100)
          .round();

      _assignedVehiclee = _assignedVehiclee!.copyWith(
        currentKm: newKm,
        remainingKm: updatedRemainingKm,
        usagePercent: updatedUsagePercent,
      );

      _isUpdating = false;
      showSnakBarr(context, LocaleKeys.km_update_success.tr());

      notifyListeners();
      await fetchInspectorVehicles();

      return true;
    } catch (e) {
      showSnakBarr(
        context,
        '${LocaleKeys.km_update_error.tr(args: [e.toString()])}',
      );
      _isUpdating = false;
      notifyListeners();
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
    final done = await updateVehicleKm(newKm, context);
    if (done) {}
  }

  Future<void> refresh() async {
    await fetchInspectorVehicles();
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
