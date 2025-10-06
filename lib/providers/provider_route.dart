// lib/providers/route_provider.dart
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../firebase_services/firebase_route_service.dart';
import '../models/route_model.dart';

/// Provider for Route screen
/// Shows today's route schedule with all planned branch visits
class ProviderRoute extends ChangeNotifier {
  final RouteService _routeService = RouteService();

  // State
  RouteModel? _allRoute;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  List<RouteStopModel> todaysStopsList = [];
  double todaysProgressValue = 0.0;
  int todaysCompletedCount = 0;

  // Getters
  RouteModel? get allRoute => _allRoute;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed values
  List<RouteStopModel> get stops => _allRoute?.stops ?? [];
  int get totalStops => _allRoute?.totalStops ?? 0;
  int get completedStops => _allRoute?.completedStopsCount ?? 0;
  double get completionPercent => _allRoute?.completionPercent ?? 0.0;

  RouteStopModel? get currentStop {
    if (_allRoute == null) return null;
    try {
      return _allRoute!.stops.firstWhere((stop) => stop.isCurrent);
    } catch (e) {
      return null;
    }
  }

  RouteStopModel? get nextStop {
    if (_allRoute == null) return null;
    try {
      return _allRoute!.stops.firstWhere((stop) => stop.isPending);
    } catch (e) {
      return null;
    }
  }

  void calculateTodaysData() {
    if (_allRoute == null) {
      todaysStopsList = [];
      todaysProgressValue = 0.0;
      todaysCompletedCount = 0;
      return;
    }

    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month}-${today.day}";

    // Filter stops for today
    todaysStopsList = _allRoute!.stops
        .where((stop) => stop.timeSlot == todayKey)
        .toList();

    // Completed stops count
    todaysCompletedCount = todaysStopsList
        .where((stop) => stop.status == AppConstants.completed)
        .length;

    // Progress
    todaysProgressValue = todaysStopsList.isEmpty
        ? 0.0
        : todaysCompletedCount / todaysStopsList.length;
  }

  // Initialize
  Future<void> initialize() async {
    await fetchAllRoutes();
  }

  // Fetch today's route
  Future<void> fetchAllRoutes() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _allRoute = await _routeService.getAllRoutes(loggedInUser!.id);
      calculateTodaysData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading route: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_errorMessage);
    }
  }

  // Stream-based initialization (real-time updates)
  void initializeWithStreams() {

    _routeService.streamTodaysRoute(loggedInUser!.id).listen((route) {
      _allRoute = route;
      notifyListeners();
    });
  }

  // Fetch route by specific date
  Future<void> fetchRouteByDate(DateTime date) async {
    try {
      _isLoading = true;
      _selectedDate = date;
      _errorMessage = null;
      notifyListeners();

      _allRoute = await _routeService.getRouteByDate(loggedInUser!.id, date);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading route: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_errorMessage);
    }
  }

  // Update stop status
  Future<void> updateStopStatus(int stopIndex, String newStatus) async {
    if (_allRoute == null) return;

    try {
      await _routeService.updateStopStatus(_allRoute!.id, stopIndex, newStatus);

      // Update local state immediately for better UX
      final updatedStops = List<RouteStopModel>.from(_allRoute!.stops);
      updatedStops[stopIndex] = RouteStopModel(
        timeSlot: updatedStops[stopIndex].timeSlot,
        branchId: updatedStops[stopIndex].branchId,
        branchName: updatedStops[stopIndex].branchName,
        status: newStatus,
        inspectionId: updatedStops[stopIndex].inspectionId,
        order: updatedStops[stopIndex].order,
      );

      _allRoute = RouteModel(
        id: _allRoute!.id,
        date: _allRoute!.date,
        inspectorId: _allRoute!.inspectorId,
        inspectorName: _allRoute!.inspectorName,
        stops: updatedStops,
        createdAt: _allRoute!.createdAt,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error updating stop status: ${e.toString()}';
      notifyListeners();
      print(_errorMessage);
    }
  }

  // Mark stop as completed
  Future<void> markStopCompleted(int stopIndex) async {
    await updateStopStatus(stopIndex, 'completed');
  }

  // Mark stop as current
  Future<void> markStopCurrent(int stopIndex) async {
    await updateStopStatus(stopIndex, 'current');
  }

  // Mark stop as pending
  Future<void> markStopPending(int stopIndex) async {
    await updateStopStatus(stopIndex, 'pending');
  }

  // Get stop by index
  RouteStopModel? getStopByIndex(int index) {
    if (_allRoute == null || index >= _allRoute!.stops.length) {
      return null;
    }
    return _allRoute!.stops[index];
  }

  // Get stop index by branch ID
  int? getStopIndexByBranchId(String branchId) {
    if (_allRoute == null) return null;
    return _allRoute!.stops.indexWhere((stop) => stop.branchId == branchId);
  }

  // Check if there's a route for today
  bool get hasRouteForToday => _allRoute != null;

  // Refresh
  Future<void> refresh() async {
    await fetchAllRoutes();
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
