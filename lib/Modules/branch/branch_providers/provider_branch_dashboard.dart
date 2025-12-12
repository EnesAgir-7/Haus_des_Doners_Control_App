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

  // Stream subscription for realtime branch updates
  StreamSubscription<BranchModel?>? _branchSubscription;

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
    // Use the stream-based loader so UI reflects live changes
    loadBranchStream();
  }

  void loadBranchStream({bool forceReinit = true}) {
    final branchId = loggedInUser!.id;

    // If a subscription exists and caller doesn't want to force reinit, skip.
    if (_branchSubscription != null && !forceReinit) {
      console('✅ Branch stream already active — skipping reinitialization');
      return;
    }

    // If there is an existing subscription, cancel it before creating a new one
    _branchSubscription?.cancel();
    _branchSubscription = null;

    console('📡 Initializing branch stream for $branchId...');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _branchSubscription = _dashboardService
        .streamBranch(branchId)
        .listen(
          (branch) {
            _branchInfo = branch;
            _errorMessage = null;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = '$error';
            _isLoading = false;
            notifyListeners();
            console('Branch stream error: $error');
          },
          cancelOnError: false,
        );
  }

  // Refresh dashboard data
  Future<void> refresh() async {
    _errorMessage = null;
    // Reinitialize the stream to pick up any changes from scratch
    loadBranchStream(forceReinit: true);
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Cancel/close all active streams and reset relevant state. Call this when
  /// the provider is disposed or you want to stop listening to realtime updates.
  Future<void> closeAllStreams() async {
    console('🛑 Closing all streams in ProviderBranchDashboard');
    await _branchSubscription?.cancel();
    _branchSubscription = null;
    _branchInfo = null;
    _totalReports = 0;
    _unreadNotifications = 0;
    _totalDocuments = 0;
    _totalTrainings = 0;
    _recentReports = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Cleanup
  @override
  void dispose() {
    closeAllStreams();
    super.dispose();
  }
}
