import 'package:haus_des_control/core/console.dart';

import '../../../models/inspection_model.dart';
import '../../../models/task_model.dart';
import '../../../models/vehicle_model.dart';

class InspectorDataCache {
  static final Map<String, List<TaskModel>> _tasksCache = {};
  static final Map<String, List<InspectionModel>> _inspectionsCache = {};
  static final Map<String, List<VehicleModel>> _vehiclesCache = {};

  static String _getCacheKey(String inspectorId, int year, int month) {
    return '${inspectorId}_${month.toString().padLeft(2, '0')}-$year';
  }

  // Tasks Cache
  static List<TaskModel>? getTasks(String inspectorId, int year, int month) {
    return _tasksCache[_getCacheKey(inspectorId, year, month)];
  }

  static void setTasks(
    String inspectorId,
    int year,
    int month,
    List<TaskModel> tasks,
  ) {
    _tasksCache[_getCacheKey(inspectorId, year, month)] = tasks;
  }

  // Inspections Cache
  static List<InspectionModel>? getInspections(
    String inspectorId,
    int year,
    int month,
  ) {
    return _inspectionsCache[_getCacheKey(inspectorId, year, month)];
  }

  static void setInspections(
    String inspectorId,
    int year,
    int month,
    List<InspectionModel> inspections,
  ) {
    _inspectionsCache[_getCacheKey(inspectorId, year, month)] = inspections;
  }

  // Vehicles Cache

  static List<VehicleModel>? getVehicles(
    String inspectorId,
    int year,
    int month,
  ) {
    return _vehiclesCache[_getCacheKey(inspectorId, year, month)];
  }

  static void setVehicles(
    String inspectorId,
    int year,
    int month,
    List<VehicleModel> vehicles,
  ) {
    _vehiclesCache[_getCacheKey(inspectorId, year, month)] = vehicles;
  }

  // Clear all cache
  static void clearAll() {
    console("Cache Cleared");
    _tasksCache.clear();
    _inspectionsCache.clear();
    _vehiclesCache.clear();
  }

  // Clear specific inspector cache
  static void clearInspector(String inspectorId) {
    _tasksCache.removeWhere((key, _) => key.startsWith(inspectorId));
    _inspectionsCache.removeWhere((key, _) => key.startsWith(inspectorId));
    _vehiclesCache.removeWhere((key, _) => key.startsWith(inspectorId));
  }
}
