import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import '../../../models/document_model.dart';

class BranchDocumentsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get the documents subcollection reference for a specific branch
  CollectionReference _getDocumentsCollection(String branchId) {
    return _db.collection(Collections.documents).doc(branchId).collection(Collections.documentsSubCollection);
  }

  // Stream for real-time updates (perfect for branch side)
  Stream<List<DocumentModel>> getBranchDocuments(String branchId) {
    return _getDocumentsCollection(branchId)
        .orderBy(DocumentFields.uploadedAt, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DocumentModel.fromFirestore(doc, branchId))
              .toList();
        });
  }

  // One-time fetch (if you don't need real-time updates)
  Future<List<DocumentModel>> fetchBranchDocuments(String branchId) async {
    try {
      final snapshot = await _getDocumentsCollection(
        branchId,
      ).orderBy(DocumentFields.uploadedAt, descending: true).get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc, branchId))
          .toList();
    } catch (e) {
      print("Error fetching branch documents: $e");
      rethrow;
    }
  }

  // Get a single document
  Future<DocumentModel?> getDocument(String branchId, String documentId) async {
    try {
      final doc = await _getDocumentsCollection(branchId).doc(documentId).get();

      if (!doc.exists) return null;

      return DocumentModel.fromFirestore(doc, branchId);
    } catch (e) {
      print("Error fetching document: $e");
      rethrow;
    }
  }

  // Get document count for a branch
  Future<int> getDocumentCount(String branchId) async {
    try {
      final snapshot = await _getDocumentsCollection(branchId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print("Error getting document count: $e");
      return 0;
    }
  }

  // Search documents by name (for branch side search functionality)
  Stream<List<DocumentModel>> searchDocuments(String branchId, String query) {
    return _getDocumentsCollection(branchId)
        .where(DocumentFields.name, isGreaterThanOrEqualTo: query)
        .where(DocumentFields.name, isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DocumentModel.fromFirestore(doc, branchId))
              .toList();
        });
  }

  // Filter documents by file extension
  Stream<List<DocumentModel>> getDocumentsByType(
    String branchId,
    List<String> extensions,
  ) {
    return _getDocumentsCollection(branchId)
        .where(DocumentFields.fileExtension, whereIn: extensions)
        .orderBy(DocumentFields.uploadedAt, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DocumentModel.fromFirestore(doc, branchId))
              .toList();
        });
  }

  // Get recent documents (last N days)
  Stream<List<DocumentModel>> getRecentDocuments(String branchId, int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return _getDocumentsCollection(branchId)
        .where(
          DocumentFields.uploadedAt,
          isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
        )
        .orderBy(DocumentFields.uploadedAt, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DocumentModel.fromFirestore(doc, branchId))
              .toList();
        });
  }
}
