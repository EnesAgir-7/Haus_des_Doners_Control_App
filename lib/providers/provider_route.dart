import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../firebase_services/firebase_route_service.dart';
import '../models/route_model.dart';

class ProviderRoute extends ChangeNotifier {
  final RouteService _routeService = RouteService();

  // State
  RouteModel? _allRoute;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _filterDate;

  List<RouteStopModel> todaysStopsList = [];
  double todaysProgressValue = 0.0;
  int todaysCompletedCount = 0;

  // Stream subscription
  // Stream subscription
  StreamSubscription<RouteModel?>? _routeSubscription;
  String? _currentInspectorId;

  // Getters
  RouteModel? get allRoute => _allRoute;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get filterDate => _filterDate;

  // Computed values
  List<RouteStopModel> get stops => _allRoute?.stops ?? [];
  int get totalStops => _allRoute?.totalStops ?? 0;
  int get completedStops => _allRoute?.completedStopsCount ?? 0;
  double get completionPercent => _allRoute?.completionPercent ?? 0.0;

  // Filtered stops based on selected date
  List<RouteStopModel> get filteredStops {
    if (_filterDate == null) return stops;

    final filterKey =
        "${_filterDate!.year}-${_filterDate!.month}-${_filterDate!.day}";
    return stops.where((stop) => stop.timeSlot == filterKey).toList();
  }

  // Filtered completed count
  int get filteredCompletedCount {
    return filteredStops
        .where((stop) => stop.status == AppConstants.completed)
        .length;
  }

  // In ProviderRoute class, add this computed property:

  // Filtered overdue count
  int get filteredOverdueCount {
    return filteredStops.where((stop) {
      if (stop.status == AppConstants.completed) return false;

      final stopParts = stop.timeSlot.split('-');
      final stopDate = DateTime(
        int.parse(stopParts[0]),
        int.parse(stopParts[1]),
        int.parse(stopParts[2]),
      );
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      return stopDate.isBefore(todayDate);
    }).length;
  }

  // Filtered progress value
  double get filteredProgressValue {
    if (filteredStops.isEmpty) return 0.0;
    return filteredCompletedCount / filteredStops.length;
  }

  RouteStopModel? get currentStop {
    if (_allRoute == null) return null;
    try {
      return _allRoute!.stops.firstWhere((stop) => stop.isCurrent);
    } catch (_) {
      return null;
    }
  }

  RouteStopModel? get nextStop {
    if (_allRoute == null) return null;
    try {
      return _allRoute!.stops.firstWhere((stop) => stop.isPending);
    } catch (_) {
      return null;
    }
  }

  // 🔹 Set date filter
  void setDateFilter(DateTime date) {
    _filterDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  // 🔹 Clear date filter
  void clearDateFilter() {
    _filterDate = null;
    notifyListeners();
  }

  // 🔹 Calculate today’s route summary
  void calculateTodaysData() {
    if (_allRoute == null) {
      todaysStopsList = [];
      todaysProgressValue = 0.0;
      todaysCompletedCount = 0;
      return;
    }

    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month}-${today.day}";

    todaysStopsList = _allRoute!.stops
        .where((stop) => stop.timeSlot == todayKey)
        .toList();

    todaysCompletedCount = todaysStopsList
        .where((stop) => stop.status == AppConstants.completed)
        .length;

    todaysProgressValue = todaysStopsList.isEmpty
        ? 0.0
        : todaysCompletedCount / todaysStopsList.length;
  }

  // 🔹 Normal (non-stream) initialization
  Future<void> initialize() async {
    initializeWithStreams();
  }

  // 🔥 Real-time route stream initialization
  initializeWithStreams() {
    final inspectorId = loggedInUser!.id;

    if (_routeSubscription != null && _currentInspectorId == inspectorId) {
      console("Same user and stream is On");
      return;
    }

    _currentInspectorId = inspectorId;
    _routeSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _routeSubscription = _routeService
        .getAllRoutesStream(loggedInUser!.id)
        .listen(
          (route) {
            _allRoute = route;
            calculateTodaysData();
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Stream error: $error';
            _isLoading = false;
            notifyListeners();
            console(_errorMessage);
          },
        );
  }

  // 🔹 Update stop status (optimistic update)
  Future<void> updateStopStatus(int stopIndex, String newStatus) async {
    if (_allRoute == null) return;

    try {
      await _routeService.updateStopStatus(_allRoute!.id, stopIndex, newStatus);

      final updatedStops = List<RouteStopModel>.from(_allRoute!.stops);
      updatedStops[stopIndex] = RouteStopModel(
        branchTemplateId: updatedStops[stopIndex].branchTemplateId,
        timeSlot: updatedStops[stopIndex].timeSlot,
        branchId: updatedStops[stopIndex].branchId,
        branchName: updatedStops[stopIndex].branchName,
        status: newStatus,
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

      calculateTodaysData();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error updating stop status: ${e.toString()}';
      notifyListeners();
      console(_errorMessage);
    }
  }

  // 🔹 Helper mark methods
  Future<void> markStopCompleted(int stopIndex) async =>
      updateStopStatus(stopIndex, AppConstants.completed);

  Future<void> markStopCurrent(int stopIndex) async =>
      updateStopStatus(stopIndex, AppConstants.current);

  Future<void> markStopPending(int stopIndex) async =>
      updateStopStatus(stopIndex, AppConstants.pending);

  // 🔹 Utility getters
  RouteStopModel? getStopByIndex(int index) {
    if (_allRoute == null || index >= _allRoute!.stops.length) return null;
    return _allRoute!.stops[index];
  }

  int? getStopIndexByBranchId(String branchId) {
    if (_allRoute == null) return null;
    return _allRoute!.stops.indexWhere((stop) => stop.branchId == branchId);
  }

  bool get hasRouteForToday => _allRoute != null;

  // 🔹 Refresh manually
  Future<void> refresh() async {
    initializeWithStreams();
  }

  // 🔹 Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 🔹 Cleanup
  @override
  void dispose() {
    _routeSubscription?.cancel();
    super.dispose();
  }

  // 🔹 Fetch route by specific date (non-stream)
  // Future<void> fetchRouteByDate(DateTime date) async {
  //   try {
  //     _isLoading = true;
  //     _selectedDate = date;
  //     _errorMessage = null;
  //     notifyListeners();

  //     _allRoute = await _routeService.getRouteByDate(loggedInUser!.id, date);
  //     calculateTodaysData();

  //     _isLoading = false;
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = 'Error loading route: ${e.toString()}';
  //     _isLoading = false;
  //     notifyListeners();
  //     console(_errorMessage);
  //   }
  // }

  // 🔹 Fetch today's route (one-time)
  // Future<void> fetchAllRoutes() async {
  //   try {
  //     _isLoading = true;
  //     _errorMessage = null;
  //     notifyListeners();

  //     _allRoute = await _routeService.getAllRoutes(loggedInUser!.id);
  //     calculateTodaysData();

  //     _isLoading = false;
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = 'Error loading route: ${e.toString()}';
  //     _isLoading = false;
  //     notifyListeners();
  //     console(_errorMessage);
  //   }
  // }
}
