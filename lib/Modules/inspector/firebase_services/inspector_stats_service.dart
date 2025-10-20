import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/enums.dart';
import '../../../models/dashboard_statistics.dart';
import '../../../models/inspector_stats_model.dart';

class InspectorStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = Collections.inspectorStats;

  Future<DashboardStats> getDashboardStats(
    String userId, {
    TimeRange range = TimeRange.weekly,
  }) async {
    final now = DateTime.now();
    final startDate = _getStartDate(now, range);

    final results = await Future.wait([
      // _getAssignedBranchesCount(userId),
      // _getPendingTasksCount(userId),
      _getInspectionsInRange(userId, startDate),
    ]);

    final inspections = results[0];

    return DashboardStats(
      // assignedBranches: results[0] as int,
      // pendingTasks: results[0] as int,
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

  // Future<int> _getPendingTasksCount(String userId) async {
  //   final snapshot = await _db
  //       .collection(Collections.tasks)
  //       .where('assignedInspectorId', isEqualTo: userId)
  //       .where(
  //         'status',
  //         whereIn: [AppConstants.pending, AppConstants.inProgress],
  //       )
  //       .count()
  //       .get();
  //   return snapshot.count ?? 0;
  // }

  Future<List<double>> _getInspectionsInRange(
    String userId,
    DateTime startDate,
  ) async {
    final snapshot = await _db
        .collection(Collections.inspections)
        .where('inspectorId', isEqualTo: userId)
        .where('completedTime', isGreaterThanOrEqualTo: startDate)
        .where('status', isEqualTo: AppConstants.completed)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['score'] as num).toDouble())
        .toList();
  }

  double _calculateAverage(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  // Get current month stats for inspector
  Future<InspectorStatsModel?> getCurrentMonthStats(String inspectorId) async {
    try {
      final now = DateTime.now();
      final docId = '${inspectorId}_${now.month}_${now.year}';

      final doc = await _db.collection(_collection).doc(docId).get();
      if (!doc.exists) return null;

      return InspectorStatsModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting current month stats: $e');
      return null;
    }
  }

  // Stream current month stats (real-time)
  Stream<InspectorStatsModel?> streamCurrentMonthStats(String inspectorId) {
    final now = DateTime.now();
    final docId = '${inspectorId}_${now.month}_${now.year}';

    return _db.collection(_collection).doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InspectorStatsModel.fromFirestore(doc);
    });
  }

  // Get stats by month
  Future<InspectorStatsModel?> getStatsByMonth(
    String inspectorId,
    int month,
    int year,
  ) async {
    try {
      final docId = '${inspectorId}_${month}_${year}';
      final doc = await _db.collection(_collection).doc(docId).get();

      if (!doc.exists) return null;
      return InspectorStatsModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting stats by month: $e');
      return null;
    }
  }

  // Get stats history for inspector
  Future<List<InspectorStatsModel>> getStatsHistory(
    String inspectorId,
    int monthsBack,
  ) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('inspectorId', isEqualTo: inspectorId)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .limit(monthsBack)
          .get();

      return snapshot.docs
          .map((doc) => InspectorStatsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting stats history: $e');
      return [];
    }
  }

  // Update or create stats
  Future<void> updateStats(InspectorStatsModel stats) async {
    try {
      final docId = '${stats.inspectorId}_${stats.month}_${stats.year}';
      await _db
          .collection(_collection)
          .doc(docId)
          .set(stats.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error updating stats: $e');
      rethrow;
    }
  }

  // Get all inspectors stats for current month (admin)
  Future<List<InspectorStatsModel>> getAllCurrentMonthStats() async {
    try {
      final now = DateTime.now();
      final snapshot = await _db
          .collection(_collection)
          .where('month', isEqualTo: now.month)
          .where('year', isEqualTo: now.year)
          .get();

      return snapshot.docs
          .map((doc) => InspectorStatsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all current month stats: $e');
      return [];
    }
  }
}
