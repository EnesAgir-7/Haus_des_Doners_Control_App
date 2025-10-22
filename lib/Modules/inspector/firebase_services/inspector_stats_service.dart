import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/enums.dart';
import '../../../models/dashboard_statistics.dart';

class InspectorStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DashboardStats> getDashboardStats(
    String userId, {
    TimeRange range = TimeRange.weekly,
  }) async {
    final now = DateTime.now();
    final startDate = _getStartDate(now, range);

    final results = await Future.wait([
      _getInspectionsInRange(userId, startDate),
    ]);

    final inspections = results[0];

    return DashboardStats(
      inspectionsCount: inspections.length,
      averageScore: _calculateAverage(inspections),
      timeRange: range,
    );
  }

  DateTime _getStartDate(DateTime now, TimeRange range) {
    switch (range) {
      case TimeRange.daily:
        return DateTime(now.year, now.month, now.day);
      case TimeRange.weekly:
        return now.subtract(Duration(days: now.weekday - 1));
      case TimeRange.monthly:
        return DateTime(now.year, now.month, 1);
    }
  }

  Future<List<double>> _getInspectionsInRange(
    String userId,
    DateTime startDate,
  ) async {
    final snapshot = await _db
        .collection(Collections.inspections)
        .where(InspectionFields.inspectorId, isEqualTo: userId)
        .where(
          InspectionFields.completedTime,
          isGreaterThanOrEqualTo: startDate,
        )
        .where(InspectionFields.status, isEqualTo: AppConstants.completed)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()[InspectionFields.score] as num).toDouble())
        .toList();
  }

  double _calculateAverage(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}
