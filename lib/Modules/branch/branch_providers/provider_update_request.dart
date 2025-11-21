import 'package:flutter/material.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../models/branch_model.dart';
import '../firebase_services/branch_dashboard_service.dart';

class ProviderUpdateRequest extends ChangeNotifier {
  final BranchDashboardService _service = BranchDashboardService();

  // State
  BranchModel? _branchInfo;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Getters
  BranchModel? get branchInfo => _branchInfo;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // Initialize
  Future<void> initialize() async {
    final branchId = loggedInUser!.id;

    _isLoading = true;
    notifyListeners();

    try {
      _branchInfo = await _service.getBranchInfo(branchId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading branch info: $e';
      _isLoading = false;
      notifyListeners();
      console(_errorMessage);
    }
  }

  // Submit update request
  Future<bool> submitUpdateRequest({
    required Map<String, dynamic> requestedChanges,
    String? notes,
  }) async {
    if (_branchInfo == null) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.submitUpdateRequest(
        branchId: _branchInfo!.id,
        branchName: _branchInfo!.name,
        requestedChanges: requestedChanges,
        notes: notes,
      );

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error submitting request: $e';
      _isSubmitting = false;
      notifyListeners();
      console(_errorMessage);
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
