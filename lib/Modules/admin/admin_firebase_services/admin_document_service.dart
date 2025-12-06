import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import '../../../models/document_model.dart';

class AdminDocumentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection name constants

  // Get the documents subcollection reference for a specific branch
  CollectionReference _getDocumentsCollection(String branchId) {
    return _db
        .collection(Collections.documents)
        .doc(branchId)
        .collection(Collections.documentsSubCollection);
  }

  // Upload file to Firebase Storage
  Future<Map<String, String>> uploadFile(
    File file,
    String fileName,
    String branchId,
  ) async {
    try {
      // Create unique file path with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final sanitizedFileName = fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final storagePath = 'documents/$branchId/$timestamp-$sanitizedFileName';

      // Get storage reference
      final ref = _storage.ref().child(storagePath);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(fileExtension),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'branchId': branchId,
          'originalFileName': fileName,
        },
      );

      // Upload file
      final uploadTask = await ref.putFile(file, metadata);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return {'fileUrl': downloadUrl, 'storagePath': storagePath};
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // Add new document to Firestore
  Future<String> addDocument(DocumentModel document) async {
    try {
      final docRef = await _getDocumentsCollection(
        document.branchId,
      ).add(document.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Get documents with pagination
  Future<Map<String, dynamic>> getDocuments({
    required String branchId,
    int pageSize = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _getDocumentsCollection(
        branchId,
      ).orderBy(DocumentFields.uploadedAt, descending: true).limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final documents = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc, branchId))
          .toList();

      return {
        'documents': documents,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == pageSize,
      };
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Update document metadata
  Future<void> updateDocument(
    String branchId,
    String documentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Add updatedAt timestamp
      updates['updatedAt'] = Timestamp.now();

      await _getDocumentsCollection(branchId).doc(documentId).update(updates);
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Delete document (including file from storage)
  Future<void> deleteDocument(
    String branchId,
    String documentId,
    String fileUrl,
  ) async {
    try {
      // Delete from Firestore first
      await _getDocumentsCollection(branchId).doc(documentId).delete();

      // Then try to delete from Storage
      try {
        final ref = _storage.refFromURL(fileUrl);
        await ref.delete();
      } on FirebaseException catch (storageError) {
        // Log but don't throw - document is already deleted from Firestore
        print('${storageError.message}');
      }
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Get single document
  Future<DocumentModel?> getDocument(String branchId, String documentId) async {
    try {
      final doc = await _getDocumentsCollection(branchId).doc(documentId).get();

      if (!doc.exists) return null;

      return DocumentModel.fromFirestore(doc, branchId);
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Get document count for a branch
  Future<int> getDocumentCount(String branchId) async {
    try {
      final snapshot = await _getDocumentsCollection(branchId).count().get();
      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      print('${e.message}');
      return 0;
    } catch (e) {
      print('$e');
      return 0;
    }
  }

  // Search documents by name
  Future<List<DocumentModel>> searchDocuments(
    String branchId,
    String searchQuery,
  ) async {
    try {
      final lowercaseQuery = searchQuery.toLowerCase();

      final snapshot = await _getDocumentsCollection(branchId)
          .orderBy(DocumentFields.name)
          .startAt([lowercaseQuery])
          .endAt(['$lowercaseQuery\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc, branchId))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Get recent documents (last N days)
  Future<List<DocumentModel>> getRecentDocuments(
    String branchId,
    int days,
  ) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _getDocumentsCollection(branchId)
          .where(
            DocumentFields.uploadedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .orderBy(DocumentFields.uploadedAt, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc, branchId))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Get total storage used by branch
  Future<int> getTotalStorageSize(String branchId) async {
    try {
      final snapshot = await _getDocumentsCollection(branchId).get();

      int totalSize = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalSize += (data[DocumentFields.fileSize] as int?) ?? 0;
      }

      return totalSize;
    } on FirebaseException catch (e) {
      print('${e.message}');
      return 0;
    } catch (e) {
      print('$e');
      return 0;
    }
  }

  // Batch delete multiple documents
  Future<Map<String, dynamic>> batchDeleteDocuments(
    String branchId,
    List<String> documentIds,
  ) async {
    try {
      final batch = _db.batch();
      final failedDeletions = <String>[];
      final successfulDeletions = <String>[];

      for (final docId in documentIds) {
        try {
          // Get document to retrieve file URL
          final doc = await getDocument(branchId, docId);
          if (doc != null) {
            // Add to batch
            batch.delete(_getDocumentsCollection(branchId).doc(docId));

            // Try to delete from storage
            try {
              final ref = _storage.refFromURL(doc.fileUrl);
              await ref.delete();
            } catch (storageError) {
              print('$storageError');
            }

            successfulDeletions.add(docId);
          }
        } catch (e) {
          failedDeletions.add(docId);
          print('$docId: $e');
        }
      }

      // Commit batch
      if (successfulDeletions.isNotEmpty) {
        await batch.commit();
      }

      return {
        'successful': successfulDeletions,
        'failed': failedDeletions,
        'totalProcessed': documentIds.length,
      };
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Check if document exists
  Future<bool> documentExists(String branchId, String documentId) async {
    try {
      final doc = await _getDocumentsCollection(branchId).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking document existence: $e');
      return false;
    }
  }

  // Get storage path from URL
  String? getStoragePathFromUrl(String fileUrl) {
    try {
      final uri = Uri.parse(fileUrl);
      final path = uri.pathSegments;
      final index = path.indexOf('o');
      if (index != -1 && index + 1 < path.length) {
        return Uri.decodeComponent(path[index + 1]);
      }
      return null;
    } catch (e) {
      print('Error parsing storage path: $e');
      return null;
    }
  }

  // Duplicate document to another branch
  Future<String> duplicateDocument(
    DocumentModel document,
    String targetBranchId,
  ) async {
    try {
      final newDocument = DocumentModel(
        id: '', // Will be generated
        branchId: targetBranchId,
        name: document.name,
        description: document.description,
        fileUrl: document.fileUrl, // Same file URL
        fileName: document.fileName,
        fileSize: document.fileSize,
        fileExtension: document.fileExtension,
        uploadedAt: DateTime.now(),
        uploadedBy: document.uploadedBy,
        uploadedByName: document.uploadedByName,
      );

      return await addDocument(newDocument);
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Get documents uploaded by specific user
  Future<List<DocumentModel>> getDocumentsByUploader(
    String branchId,
    String uploaderId,
  ) async {
    try {
      final snapshot = await _getDocumentsCollection(branchId)
          .where(DocumentFields.uploadedBy, isEqualTo: uploaderId)
          .orderBy(DocumentFields.uploadedAt, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc, branchId))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      throw Exception(' $e');
    }
  }
}
