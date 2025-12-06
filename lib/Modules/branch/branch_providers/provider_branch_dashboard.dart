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

    _isLoading = true;
    notifyListeners();

    try {
      // Load branch info
      _branchInfo = await _dashboardService.getBranchInfo(branchId);
    } catch (e) {
      _errorMessage = '$e';
      _isLoading = false;
      notifyListeners();
      console(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
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
    super.dispose();
  }
}
