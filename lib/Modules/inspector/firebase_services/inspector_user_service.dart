import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../core/console.dart';
import '../../../models/inspector_history_model.dart';

class InspectorUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// Add this method to your AdminUserService class
  Stream<InspectorHistoryModel?> streamInspectorMonthStats(
    String inspectorId,
    int year,
    int month,
  ) {
    final monthKey = '${month.toString().padLeft(2, '0')}-$year';

    return _db
        .collection(Collections.inspectorStats)
        .doc(inspectorId)
        .collection("months")
        .doc(monthKey)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return null;
          }
          return InspectorHistoryModel.fromMap(snapshot.data()!);
        });
  }


  Future<List<String>> getAvailableMonths(String userId) async {
    try {
      final monthsSnapshot = await _db
          .collection(Collections.inspectorStats)
          .doc(userId)
          .collection('months')
          .get();

      final monthKeys = monthsSnapshot.docs.map((doc) => doc.id).toList();
      monthKeys.sort(); // Sort chronologically

      return monthKeys;
    } catch (e) {
      console('❌ Error fetching available months: $e');
      return [];
    }
  }
  
}
