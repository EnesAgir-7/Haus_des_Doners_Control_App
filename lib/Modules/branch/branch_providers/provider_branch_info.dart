import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../models/branch_model.dart';
import '../firebase_services/branch_dashboard_service.dart';

class ProviderBranchInfo extends ChangeNotifier {
  final BranchDashboardService _service = BranchDashboardService();

  // State
  BranchModel? _branchInfo;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _pendingRequests = [];

  // Stream subscriptions
  StreamSubscription? _requestsSubscription;

  // Getters
  BranchModel? get branchInfo => _branchInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;

  // Initialize
  Future<void> initialize() async {
    final branchId = loggedInUser!.id;

    _isLoading = true;
    notifyListeners();

    try {
      // Load branch info
      _branchInfo = await _service.getBranchInfo(branchId);

      // Start listening to update requests
      _requestsSubscription?.cancel();
      _requestsSubscription = _service
          .getUpdateRequestsStream(branchId)
          .listen(
            (requests) {
              _pendingRequests = requests;
              notifyListeners();
            },
            onError: (error) {
              console('Error loading update requests: $error');
            },
          );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading branch info: $e';
      _isLoading = false;
      notifyListeners();
      console(_errorMessage);
    }
  }

  // Refresh
  Future<void> refresh() async {
    _errorMessage = null;
    await initialize();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Cleanup
  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }
}
