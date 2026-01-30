import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/common/services/inspector_data_service.dart';
import 'package:haus_des_control/models/inspection_model.dart';
import 'package:haus_des_control/models/task_model.dart';
import 'package:haus_des_control/models/vehicle_model.dart';
import '../../../core/console.dart';

class ProviderInspectorRecords extends ChangeNotifier {
  // Source streams (broadcast)
  final Map<String, Stream<List<TaskModel>>> _tasksStreams = {};
  final Map<String, Stream<List<InspectionModel>>> _inspectionsStreams = {};
  final Map<String, Stream<List<VehicleModel>>> _vehiclesStreams = {};

  // Last known data for replay
  final Map<String, List<TaskModel>> _lastTasksData = {};
  final Map<String, List<InspectionModel>> _lastInspectionsData = {};
  final Map<String, List<VehicleModel>> _lastVehiclesData = {};

  // Subscriptions to keep source streams active and capture data
  final Map<String, StreamSubscription> _subscriptions = {};

  String _getCacheKey(String inspectorId, int year, int month) {
    return '${inspectorId}_${month.toString().padLeft(2, '0')}-$year';
  }

  Stream<List<TaskModel>> getTasksStream(
    String inspectorId,
    int year,
    int month,
  ) {
    final key = _getCacheKey(inspectorId, year, month);

    if (!_tasksStreams.containsKey(key)) {
      final broadcast = InspectorDataService.streamTasks(
        inspectorId,
        year,
        month,
      ).asBroadcastStream();
      _tasksStreams[key] = broadcast;

      _subscriptions['tasks_$key'] = broadcast.listen((data) {
        _lastTasksData[key] = data;
      });
      console('📡 Started broadcast stream for Tasks: $key');
    }

    return _createReplayStream(key, _tasksStreams[key]!, _lastTasksData[key]);
  }

  Stream<List<InspectionModel>> getInspectionsStream(
    String inspectorId,
    int year,
    int month,
  ) {
    final key = _getCacheKey(inspectorId, year, month);

    if (!_inspectionsStreams.containsKey(key)) {
      final broadcast = InspectorDataService.streamInspections(
        inspectorId,
        year,
        month,
      ).asBroadcastStream();
      _inspectionsStreams[key] = broadcast;

      _subscriptions['inspections_$key'] = broadcast.listen((data) {
        _lastInspectionsData[key] = data;
      });
      console('📡 Started broadcast stream for Inspections: $key');
    }

    return _createReplayStream(
      key,
      _inspectionsStreams[key]!,
      _lastInspectionsData[key],
    );
  }

  Stream<List<VehicleModel>> getVehiclesStream(
    String inspectorId,
    int year,
    int month,
    List<String> vehicleIds,
  ) {
    final key = _getCacheKey(inspectorId, year, month);

    if (!_vehiclesStreams.containsKey(key)) {
      final broadcast = InspectorDataService.streamVehicles(
        inspectorId,
        year,
        month,
        vehicleIds,
      ).asBroadcastStream();
      _vehiclesStreams[key] = broadcast;

      _subscriptions['vehicles_$key'] = broadcast.listen((data) {
        _lastVehiclesData[key] = data;
      });
      console('📡 Started broadcast stream for Vehicles: $key');
    }

    return _createReplayStream(
      key,
      _vehiclesStreams[key]!,
      _lastVehiclesData[key],
    );
  }

  /// Helper to yield last data immediately then follow the stream
  Stream<T> _createReplayStream<T>(
    String key,
    Stream<T> source,
    T? lastValue,
  ) async* {
    if (lastValue != null) {
      yield lastValue;
    }
    yield* source;
  }

  void cancelAllStreams() {
    console(
      '🛑 Cancelling all record streams and subscriptions in ProviderInspectorRecords',
    );
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _tasksStreams.clear();
    _inspectionsStreams.clear();
    _vehiclesStreams.clear();
    _lastTasksData.clear();
    _lastInspectionsData.clear();
    _lastVehiclesData.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    cancelAllStreams();
    super.dispose();
  }
}
