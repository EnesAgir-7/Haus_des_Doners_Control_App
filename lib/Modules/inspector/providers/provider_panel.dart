import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_firebase_services/admin_user_service.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/inspector_history_model.dart';

class ProviderPanel extends ChangeNotifier {
  final AdminUserService _userService = AdminUserService();

  bool _isLoading = false;
  String? _errorMessage;
  InspectorHistoryModel? _currentMonthStats;
  List<String> _availableMonths = [];
  String? _selectedMonthKey;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  InspectorHistoryModel? get currentMonthStats => _currentMonthStats;
  List<String> get availableMonths => _availableMonths;
  String? get selectedMonthKey => _selectedMonthKey;

  // Computed values for UI
  int get completedInspections => _currentMonthStats?.totalInspections ?? 0;

  Future<void> initialize() async {
    await loadMonthlyStats();
  }

  Future<void> loadMonthlyStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = loggedInUser!.id;
      final now = DateTime.now();

      // Load current month stats
      _currentMonthStats = await _userService.getInspectorMonthStats(
        userId,
        now.year,
        now.month,
      );

      // Get available months
      _availableMonths = await _userService.getAvailableMonths(userId);

      // Set current month as selected
      _selectedMonthKey = '${now.month.toString().padLeft(2, '0')}-${now.year}';

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading monthly stats: $e');
      _errorMessage = 'Error loading statistics: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchMonth(int year, int month) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = loggedInUser!.id;
      _currentMonthStats = await _userService.getInspectorMonthStats(
        userId,
        year,
        month,
      );

      _selectedMonthKey = '${month.toString().padLeft(2, '0')}-$year';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching month: $e');
      _errorMessage = 'Error loading month data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadMonthlyStats();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
