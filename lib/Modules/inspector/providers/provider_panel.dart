import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/inspector_history_model.dart';
import '../firebase_services/inspector_user_service.dart';

class ProviderPanel extends ChangeNotifier {
  final InspectorUserService _userService = InspectorUserService();

  bool _isLoading = false;
  String? _errorMessage;
  InspectorHistoryModel? _currentMonthStats;
  List<String> _availableMonths = [];
  String? _selectedMonthKey;

  StreamSubscription<InspectorHistoryModel?>? _statsSubscription;
  String? _currentInspectorId;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  InspectorHistoryModel? get currentMonthStats => _currentMonthStats;
  List<String> get availableMonths => _availableMonths;
  String? get selectedMonthKey => _selectedMonthKey;

  int get completedInspections => _currentMonthStats?.totalInspections ?? 0;

  /// Initialize - called when the screen loads
  Future<void> initialize() async {
    initializeWithStream();
  }

  /// Smart stream initialization (avoid multiple streams for same user)
  void initializeWithStream() async {
    final inspectorId = loggedInUser!.id;

    if (_statsSubscription != null && _currentInspectorId == inspectorId) {
      // Stream is already active for the same user
      return;
    }

    // Save current user id
    _currentInspectorId = inspectorId;

    // Cancel existing subscription if any
    await _statsSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    _selectedMonthKey = '${now.month.toString().padLeft(2, '0')}-${now.year}';

    try {
      // Fetch available months once
      _availableMonths = await _userService.getAvailableMonths(inspectorId);

      // Start streaming current month stats
      _statsSubscription = _userService
          .streamInspectorMonthStats(inspectorId, now.year, now.month)
          .listen(
            (stats) {
              _currentMonthStats = stats;
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (error) {
              debugPrint('Error streaming monthly stats: $error');
              _errorMessage = '${error.toString()}';
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      debugPrint('Error initializing monthly stats stream: $e');
      _errorMessage = ' ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switch month dynamically
  Future<void> switchMonth(int year, int month) async {
    _isLoading = true;
    notifyListeners();

    try {
      final inspectorId = loggedInUser!.id;
      _selectedMonthKey = '${month.toString().padLeft(2, '0')}-$year';

      // Cancel previous subscription
      await _statsSubscription?.cancel();

      // Start streaming new month stats
      _statsSubscription = _userService
          .streamInspectorMonthStats(inspectorId, year, month)
          .listen(
            (stats) {
              _currentMonthStats = stats;
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (error) {
              debugPrint('Error switching month: $error');
              _errorMessage = '${error.toString()}';
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      debugPrint('Error switching month: $e');
      _errorMessage = ' ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh available months
  Future<void> refresh() async {
    try {
      final inspectorId = loggedInUser!.id;
      _availableMonths = await _userService.getAvailableMonths(inspectorId);
      notifyListeners();
      // Stream will automatically update current month stats
    } catch (e) {
      debugPrint('Error refreshing months: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Cancel all active streams and reset state
  void cancelAllStreams() async {
    debugPrint('🛑 Cancelling all streams in ProviderPanel');
    await _statsSubscription?.cancel();
    _statsSubscription = null;
    _currentInspectorId = null;
    _currentMonthStats = null;
    _availableMonths = [];
    _selectedMonthKey = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelAllStreams();
    super.dispose();
  }
}
