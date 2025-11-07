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

    // Get aggregated data (count + sum for average)
    final query = _db
        .collection(Collections.inspections)
        .where(InspectionFields.inspectorId, isEqualTo: userId)
        .where(
          InspectionFields.completedTime,
          isGreaterThanOrEqualTo: startDate,
        )
        .where(InspectionFields.status, isEqualTo: AppConstants.completed);

    // This is more efficient than fetching all docs
    final snapshot = await query.get();

    int count = snapshot.size;
    double totalScore = 0.0;

    for (var doc in snapshot.docs) {
      final score = doc.data()[InspectionFields.score]?.toString() ?? "0";
      totalScore += double.tryParse(score.split('/').first) ?? 0.0;
    }

    return DashboardStats(
      inspectionsCount: count,
      averageScore: count > 0 ? totalScore / count : 0.0,
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
}
