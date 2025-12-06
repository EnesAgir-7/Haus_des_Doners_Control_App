import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String branchId;
  final String name;
  final String description;
  final String fileUrl;
  final String fileName;
  final int fileSize; // in bytes
  final String fileExtension;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String uploadedByName;

  DocumentModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.fileExtension,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.uploadedByName,
  });

  factory DocumentModel.fromFirestore(DocumentSnapshot doc, String branchId) {
    final data = doc.data() as Map<String, dynamic>;
    return DocumentModel(
      id: doc.id,
      branchId: branchId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      fileSize: data['fileSize'] ?? 0,
      fileExtension: data['fileExtension'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedByName: data['uploadedByName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'name': name,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileExtension': fileExtension,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

// Constants
class DocumentFields {
  static const String name = 'name';
  static const String description = 'description';
  static const String fileUrl = 'fileUrl';
  static const String fileName = 'fileName';
  static const String fileSize = 'fileSize';
  static const String fileExtension = 'fileExtension';
  static const String uploadedAt = 'uploadedAt';
  static const String uploadedBy = 'uploadedBy';
  static const String uploadedByName = 'uploadedByName';
  static const String branchId = 'branchId';
}
