// lib/providers/panel_provider.dart
import 'package:flutter/material.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/enums.dart';
import '../firebase_services/inspector_stats_service.dart';
import '../../../models/dashboard_statistics.dart';

/// Provider for Panel (Dashboard) screen
/// Shows inspector's monthly stats and overview
class ProviderPanel extends ChangeNotifier {
  final InspectorStatsService _statsService = InspectorStatsService();

  bool _isLoading = false;
  String? _errorMessage;

  // int _totalBranches = 0;
  int _completedInspections = 0;
  // int _pendingTasks = 0;
  double _averageScore = 0.0;

  // int get totalBranches => _totalBranches;
  int get completedInspections => _completedInspections;
  // int get pendingTasks => _pendingTasks;
  double get averageScore => _averageScore;

  DashboardStats? _stats;
  TimeRange _selectedRange = TimeRange.weekly;
  TimeRange get selectedRange => _selectedRange;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardStats? get stats => _stats;

  // Initialize - call this when screen loads
  Future<void> initialize() async {
    // await fetchDashboardData();
    await loadDashboardStats();
  }

  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stats = await _statsService.getDashboardStats(
        loggedInUser!.id,
        range: _selectedRange,
      );

      // _totalBranches = stats.assignedBranches;
      _completedInspections = stats.inspectionsCount;
      // _pendingTasks = stats.pendingTasks;
      _averageScore = stats.averageScore;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      _errorMessage = 'Error loading dashboard: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_errorMessage);
    }
  }

  Future<void> changeTimeRange(TimeRange range) async {
    _selectedRange = range;
    notifyListeners();
    await loadDashboardStats();
  }

  // Refresh data
  Future<void> refresh() async {
    // await fetchDashboardData();
    await loadDashboardStats();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
