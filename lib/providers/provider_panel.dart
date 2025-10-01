// lib/providers/panel_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_services/firebase_stats_service.dart';
import '../firebase_services/firebase_user_service.dart';
import '../models/user_model.dart';
import '../models/inspector_stats_model.dart';
/// Provider for Panel (Dashboard) screen
/// Shows inspector's monthly stats and overview
class PanelProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final StatsService _statsService = StatsService();

  // State
  UserModel? _currentUser;
  InspectorStatsModel? _currentMonthStats;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  InspectorStatsModel? get currentMonthStats => _currentMonthStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed values for dashboard
  int get totalBranches => _currentMonthStats?.totalBranches ?? 0;
  int get completedInspections => _currentMonthStats?.completedInspections ?? 0;
  int get pendingInspections => _currentMonthStats?.pendingInspections ?? 0;
  double get averageScore => _currentMonthStats?.averageScore ?? 0.0;
  double get progressPercent => _currentMonthStats?.progressPercent ?? 0.0;
  int get remainingInspections => _currentMonthStats?.remainingInspections ?? 0;

  // Initialize - call this when screen loads
  Future<void> initialize() async {
    await fetchDashboardData();
  }

  // Fetch all dashboard data
  Future<void> fetchDashboardData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get current user ID from Firebase Auth
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user data
      _currentUser = await _userService.getUserById(userId);
      if (_currentUser == null) {
        throw Exception('User data not found');
      }

      // Fetch current month stats
      _currentMonthStats = await _statsService.getCurrentMonthStats(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading dashboard: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_errorMessage);
    }
  }

  // Stream-based initialization (real-time updates)
  void initializeWithStreams() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Listen to user changes
    _userService.streamUserById(userId).listen((user) {
      _currentUser = user;
      notifyListeners();
    });

    // Listen to stats changes
    _statsService.streamCurrentMonthStats(userId).listen((stats) {
      _currentMonthStats = stats;
      notifyListeners();
    });
  }

  // Refresh data
  Future<void> refresh() async {
    await fetchDashboardData();
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
