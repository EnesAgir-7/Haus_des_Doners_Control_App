import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';

import '../../../common_services/firebase_auth_service.dart';
import '../../../models/branch_model.dart';
import '../../../models/inspector_history_model.dart';
import '../../../models/user_model.dart';
import '../../../models/vehicle_model.dart';
import '../../inspector/widgets/custom_toast.dart';
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
        _error = LocaleKeys.inspectors_stream_error.tr(
          args: [error.toString()],
        );
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

  Future<void> getInspectorStatistics(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current month stats
      final now = DateTime.now();
      _currentMonthStats = await _userService.getInspectorMonthStats(
        userId,
        now.year,
        now.month,
      );

      // Get list of available months (lightweight)
      final availableMonths = await _userService.getAvailableMonths(userId);

      // Store inspector ID and available months
      _inspectorAllData = InspectorAllMonthsData(
        inspectorId: userId,
        availableMonths: availableMonths,
        lastUpdated: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Switch month without API call
  Future<void> switchMonth(int year, int month) async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentMonthStats = await _userService.getInspectorMonthStats(
        _inspectorAllData!.inspectorId,
        year,
        month,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
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

  // Unassign branch from inspector
  Future<void> unassignBranchFromInspector(
    String branchId,
    String inspectionId,
    String branchName,
    BuildContext context,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _branchService.removeBranchFromInspector(
        branchName: branchName,
        context: context,
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

  // Create new user (inspector or admin)
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? region,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authHelper.createUserWithEmail(
        email,
        password,
      );
      final userId = userCredential.user!.uid;

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

      try {
        await _userService.createUser(userId, user);
      } catch (firestoreError) {
        await userCredential.user!.delete();
        throw Exception(
          LocaleKeys.failed_to_save_user_data.tr(
            args: [firestoreError.toString()],
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error creating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateInspectorPassword({
    required String inspectorUid,
    required String newPassword,
    required BuildContext parentContext,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authHelper.updateInspectorPassword(
        inspectorUid: inspectorUid,
        newPassword: newPassword,
      );

      _isLoading = false;
      notifyListeners();

      if (parentContext.mounted) {
        showSnakBarr(parentContext, LocaleKeys.password_updated_success.tr());
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      console(e);
      if (parentContext.mounted) {
        showSnakBarr(
          parentContext,
          LocaleKeys.error_updating_password.tr(args: [e.toString()]),
        );
      }
    }
  }

  Future<void> deleteInspector({
    required String inspectorUid,
    required BuildContext parentContext,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authHelper.deleteInspectorAccount(inspectorUid: inspectorUid);

      _isLoading = false;
      notifyListeners();

      if (parentContext.mounted) {
        showSnakBarr(parentContext, LocaleKeys.inspector_deleted_success.tr());
        Navigator.of(parentContext).pop(); // go back only on success
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (parentContext.mounted) {
        showSnakBarr(parentContext, "$e");
      }
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

  Future<void> updateUser({
    required String userId,
    String? name,
    String? region,
    String? role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _userService.updateUserDetails(
        userId: userId,
        name: name,
        region: region,
        role: role,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
