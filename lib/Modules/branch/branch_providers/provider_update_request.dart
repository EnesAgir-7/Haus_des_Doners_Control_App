import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../models/branch_model.dart';
import '../../../translations/locale_keys.g.dart';
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
      _errorMessage = '${LocaleKeys.errorLoadingBranches.tr()}: $e';
      _isLoading = false;
      notifyListeners();
      console(_errorMessage);
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
