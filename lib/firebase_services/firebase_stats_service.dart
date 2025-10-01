import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inspector_stats_model.dart';

class StatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'inspectorStats';

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
