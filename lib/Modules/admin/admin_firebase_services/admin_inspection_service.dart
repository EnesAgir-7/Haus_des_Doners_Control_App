import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../models/inspection_model.dart';

class AdminInspectionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = Collections.inspections;

  Stream<List<InspectionModel>> recentInspectionsStream() {
    return FirebaseFirestore.instance
        .collection('inspections')
        .orderBy('updatedAt', descending: true)
        .limit(4)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InspectionModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<Map<String, dynamic>> getInspections({
    int pageSize = 50,
    String? searchQuery,
    String? branchId,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _db.collection(_collection);

      // 🔹 Filter by branch if provided
      if (branchId != null) {
        query = query.where(InspectionFields.branchId, isEqualTo: branchId);
      }

      // 🔹 Handle search
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .orderBy(InspectionFields.branchName)
            .startAt([searchQuery])
            .endAt(['$searchQuery\uf8ff']);
      } else {
        query = query.orderBy(InspectionFields.updatedAt, descending: true);
      }

      // 🔹 Pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(pageSize);

      final snapshot = await query.get();

      final inspections = snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();

      return {
        'inspections': inspections,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == pageSize,
      };
    } catch (e) {
      print('Error getting inspections: $e');
      rethrow;
    }
  }

  Future<void> deleteInspection(String inspectionId) async {
    try {
      await _db.collection(_collection).doc(inspectionId).delete();
    } catch (e) {
      print('Error deleting inspection: $e');
      rethrow;
    }
  }
}
