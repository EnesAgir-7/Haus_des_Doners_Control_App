import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../common_services/firebase_auth_service.dart';
import '../../../models/branch_model.dart';
import '../../../models/inspector_history_model.dart';
import '../../../models/user_model.dart';
import '../../../models/vehicle_model.dart';
import '../admin_firebase_services/admin_branch_service.dart';
import '../admin_firebase_services/admin_user_service.dart';
import '../admin_firebase_services/admin_vehicle_service.dart';

class ProviderAdminUsers extends ChangeNotifier {
  final AdminUserService _userService = AdminUserService();
  final AdminBranchService _branchService = AdminBranchService();
  final AdminVehicleService _vehicleService = AdminVehicleService();
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();

  StreamSubscription<List<UserModel>>? _inspectorsSubscription;
  InspectorAllMonthsData? _inspectorAllData;
  InspectorHistoryModel? _currentMonthStats;

  List<UserModel> _inspectors = [];
  List<BranchModel> _unAssignedBranches = [];
  List<VehicleModel> _allVehicles = [];
  String? _currentUserId;
  InspectorHistoryModel? get currentMonthStats => _currentMonthStats;
  InspectorAllMonthsData? get inspectorAllData => _inspectorAllData;

  String? _error;
  bool _isLoading = false;
  String _searchQuery = '';

  List<BranchModel> get unassignedBranches => _unAssignedBranches;
  // Getters
  List<UserModel> get inspectors => _inspectors
      .where(
        (inspector) =>
            inspector.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            inspector.serviceAccount.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
      )
      .toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  streamAllInspectors() {
    if (_currentUserId == loggedInUser?.id && _inspectorsSubscription != null) {
      print("Streams already initialized for this user");
      return;
    }

    _currentUserId = loggedInUser?.id;

    _inspectorsSubscription?.cancel();

    _inspectorsSubscription = _userService.streamAllInspectors().listen(
      (inspectorList) {
        _inspectors = inspectorList;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Inspectors stream error: $error';
        notifyListeners();
      },
    );
  }

  // Get inspector details with branches and vehicle
  Future<Map<String, dynamic>> getInspectorDetails(String inspectorId) async {
    try {
      final branches = await _branchService.getInspectorBranches(inspectorId);
      final List<VehicleModel> vehicles = await _vehicleService
          .getVehicleByInspector(inspectorId);

      return {'branches': branches, 'vehicles': vehicles};
    } catch (e) {
      rethrow;
    }
  }

  Future getInspectorStatistics(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _inspectorAllData = await _userService.getInspectorStats(userId);

      // Set current month as default
      if (_inspectorAllData != null) {
        final now = DateTime.now();
        _currentMonthStats = _inspectorAllData!.getMonth(now.year, now.month);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Switch month without API call
  void switchMonth(int year, int month) {
    if (_inspectorAllData != null) {
      _currentMonthStats = _inspectorAllData!.getMonth(year, month);
      notifyListeners();
    }
  }

  // Update inspector
  Future updateInspector(String inspectorId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _userService.updateInspector(inspectorId, data);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = true;
      notifyListeners();
      rethrow;
    }
  }

  // Get unassigned branches
  Future<List<BranchModel>> getUnassignedBranches() async {
    try {
      if (_unAssignedBranches.isEmpty) {
        _unAssignedBranches = await _branchService.getUnassignedBranches();
      }
      return _unAssignedBranches;
    } catch (e) {
      rethrow;
    }
  }

  // Assign branch to inspector
  Future<void> assignBranchToInspector(
    String inspectorId,
    String branchId,
  ) async {
    try {
      final inspector = _inspectors.firstWhere((i) => i.id == inspectorId);
      await _branchService.updateBranchAssignedInspector(branchId, {
        InspectorFields.id: inspector.id,
        InspectorFields.name: inspector.name,
      });

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Unassign branch from inspector
  Future<void> unassignBranchFromInspector(
    String branchId,
    String inspectionId,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _branchService.removeBranchFromInspector(
        branchId: branchId,
        inspectorId: inspectionId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get unassigned vehicles
  Future<List<VehicleModel>> getUnassignedVehicles() async {
    try {
      if (_allVehicles.isEmpty) {
        _allVehicles = await _vehicleService.getAllVehicles();
      }
      return _allVehicles
          .where((vehicle) => vehicle.assignedInspector == null)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Assign vehicle to inspector
  Future<void> assignVehicleToInspector(
    String inspectorId,
    String vehicleId,
  ) async {
    try {
      final inspector = _inspectors.firstWhere((i) => i.id == inspectorId);

      await _vehicleService.assignVehicleToInspector(
        vehicleId,
        inspector.id,
        inspector.name,
      );

      _allVehicles = await _vehicleService.getAllVehicles();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Unassign vehicle from inspector
  Future<void> unassignVehicleFromInspector(String vehicleId) async {
    try {
      await _vehicleService.unassignVehicle(vehicleId);

      // Refresh vehicles list
      _allVehicles = await _vehicleService.getAllVehicles();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Create new user (inspector or admin)
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? region,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final userId = await _authHelper.createUser(
        email: email,
        password: password,
      );

      // 2. Create user model
      final user = UserModel(
        id: userId,
        name: name,
        serviceAccount: email,
        role: role,
        active: true,
        region: region,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      // 3. Save to appropriate collection
      await _userService.createUser(userId, user);

      // 4. Add to local state if inspector
      if (role.toLowerCase() == 'inspector') {
        _inspectors.add(user);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Toggle inspector active status
  Future<void> toggleInspectorActive(String inspectorId, bool active) async {
    try {
      await _userService.updateInspector(inspectorId, {'active': active});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
