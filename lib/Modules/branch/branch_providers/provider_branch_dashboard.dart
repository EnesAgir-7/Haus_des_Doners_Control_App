import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../models/branch_model.dart';
import '../firebase_services/branch_dashboard_service.dart';

class ProviderBranchDashboard extends ChangeNotifier {
  final BranchDashboardService _dashboardService = BranchDashboardService();

  // State
  BranchModel? _branchInfo;
  bool _isLoading = false;
  String? _errorMessage;

  // Dashboard stats
  int _totalReports = 0;
  int _unreadNotifications = 0;
  int _totalDocuments = 0;
  int _totalTrainings = 0;
  List<dynamic> _recentReports = [];

  // Stream subscriptions
  StreamSubscription? _dashboardSubscription;
  String? _currentBranchId;

  // Getters
  BranchModel? get branchInfo => _branchInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalReports => _totalReports;
  int get unreadNotifications => _unreadNotifications;
  int get totalDocuments => _totalDocuments;
  int get totalTrainings => _totalTrainings;
  List<dynamic> get recentReports => _recentReports;

  // Initialize with real-time streams
  Future<void> initialize() async {
    final branchId = loggedInUser!.id;

    if (_dashboardSubscription != null && _currentBranchId == branchId) {
      console("Same branch and stream is already active");
      return;
    }

    _currentBranchId = branchId;
    _dashboardSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    try {
      // Load branch info
      _branchInfo = await _dashboardService.getBranchInfo(branchId);

      // Start listening to dashboard stats
      _dashboardSubscription = _dashboardService
          .getDashboardStatsStream(branchId)
          .listen(
            (stats) {
              _totalReports = stats['totalReports'] ?? 0;
              _unreadNotifications = stats['unreadNotifications'] ?? 0;
              _totalDocuments = stats['totalDocuments'] ?? 0;
              _totalTrainings = stats['totalTrainings'] ?? 0;
              _recentReports = stats['recentReports'] ?? [];
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = 'Stream Error: $error';
              _isLoading = false;
              notifyListeners();
              console(_errorMessage);
            },
          );
    } catch (e) {
      _errorMessage = 'Initialization Error: $e';
      _isLoading = false;
      notifyListeners();
      console(_errorMessage);
    }
  }

  // Refresh dashboard data
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
    _dashboardSubscription?.cancel();
    super.dispose();
  }
}
