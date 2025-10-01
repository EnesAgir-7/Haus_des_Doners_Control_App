import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inspection_model.dart';

class InspectionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'inspections';

  // Get inspections by branch
  Future<List<InspectionModel>> getInspectionsByBranch(String branchId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('branchId', isEqualTo: branchId)
          .orderBy('scheduledTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting inspections by branch: $e');
      return [];
    }
  }

  // Stream inspections by branch (real-time)
  Stream<List<InspectionModel>> streamInspectionsByBranch(String branchId) {
    return _db
        .collection(_collection)
        .where('branchId', isEqualTo: branchId)
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InspectionModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get inspections by inspector
  Future<List<InspectionModel>> getInspectionsByInspector(
    String inspectorId,
  ) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('inspectorId', isEqualTo: inspectorId)
          .orderBy('scheduledTime', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting inspections by inspector: $e');
      return [];
    }
  }

  // Get today's inspections for inspector
  Future<List<InspectionModel>> getTodaysInspections(String inspectorId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final snapshot = await _db
          .collection(_collection)
          .where('inspectorId', isEqualTo: inspectorId)
          .where('scheduledTime', isGreaterThanOrEqualTo: startOfDay)
          .where('scheduledTime', isLessThan: endOfDay)
          .orderBy('scheduledTime')
          .get();

      return snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting today\'s inspections: $e');
      return [];
    }
  }

  // Get all inspections (admin)
  Future<List<InspectionModel>> getAllInspections({
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _db.collection(_collection);

      if (startDate != null) {
        query = query.where('scheduledTime', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('scheduledTime', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query
          .orderBy('scheduledTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => InspectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all inspections: $e');
      return [];
    }
  }

  // Get single inspection
  Future<InspectionModel?> getInspectionById(String inspectionId) async {
    try {
      final doc = await _db.collection(_collection).doc(inspectionId).get();
      if (!doc.exists) return null;
      return InspectionModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting inspection: $e');
      return null;
    }
  }

  // Create inspection
  Future<String> createInspection(InspectionModel inspection) async {
    try {
      final docRef = await _db.collection(_collection).add(inspection.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating inspection: $e');
      rethrow;
    }
  }

  // Update inspection
  Future<void> updateInspection(
    String inspectionId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection(_collection).doc(inspectionId).update(data);
    } catch (e) {
      print('Error updating inspection: $e');
      rethrow;
    }
  }

  // Complete inspection
  Future<void> completeInspection(
    String inspectionId,
    Map<String, dynamic> categoryScores,
    double totalScore,
    String overallNotes,
  ) async {
    try {
      await _db.collection(_collection).doc(inspectionId).update({
        'status': 'completed',
        'completedTime': FieldValue.serverTimestamp(),
        'categories': categoryScores,
        'score': totalScore,
        'overallNotes': overallNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error completing inspection: $e');
      rethrow;
    }
  }

  // Delete inspection
  Future<void> deleteInspection(String inspectionId) async {
    try {
      await _db.collection(_collection).doc(inspectionId).delete();
    } catch (e) {
      print('Error deleting inspection: $e');
      rethrow;
    }
  }
}
