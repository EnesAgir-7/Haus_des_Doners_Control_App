import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

class InspectionModel {
  final String id;
  final String branchId;
  final String branchName;
  final String inspectorId;
  final String? inspectorName;
  final String scheduledTime;
  final DateTime? completedTime;
  final String status; // "scheduled" | "completed" | "pending" | "current"
  final double score;
  final Map<String, InspectionCategoryModel> categories;
  final String overallNotes;
  final String? pdfReportUrl; // Firebase Storage URL only
  final DateTime createdAt;
  final DateTime updatedAt;

  InspectionModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.inspectorId,
    required this.inspectorName,
    required this.scheduledTime,
    this.completedTime,
    required this.status,
    required this.score,
    required this.categories,
    required this.overallNotes,
    this.pdfReportUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory to load from Firestore
  factory InspectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawCategories = data['categories'] as Map<String, dynamic>? ?? {};

    // Convert categories map into Map<String, InspectionCategoryModel>
    final parsedCategories = rawCategories.map(
      (key, value) =>
          MapEntry(key, InspectionCategoryModel.fromMap(value ?? {})),
    );

    return InspectionModel(
      id: doc.id,
      branchId: data['branchId'] ?? '',
      branchName: data['branchName'] ?? '',
      inspectorId: data['inspectorId'] ?? '',
      inspectorName: data['inspectorName'],
      scheduledTime: data['scheduledTime'],
      completedTime: data['completedTime'] != null
          ? (data['completedTime'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      score: (data['score'] ?? 0.0).toDouble(),
      categories: parsedCategories,
      overallNotes: data['overallNotes'] ?? '',
      pdfReportUrl: data['pdfReportUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'scheduledTime': scheduledTime,
      'completedTime': completedTime != null
          ? Timestamp.fromDate(completedTime!)
          : null,
      'status': status,
      'score': score,
      'categories': categories.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'pdfReportUrl': pdfReportUrl,
      'overallNotes': overallNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isCompleted => status == AppConstants.completed;
  bool get isPending => status == AppConstants.pending;
  bool get isCurrent => status == AppConstants.current;
}

class InspectionCategoryModel {
  final int score; // 1-4 rating
  final List<String> photos; // URLs after upload
  final String notes;

  InspectionCategoryModel({
    required this.score,
    required this.photos,
    required this.notes,
  });

  factory InspectionCategoryModel.fromMap(Map<String, dynamic> data) {
    return InspectionCategoryModel(
      score: data['score'] ?? 0,
      photos: List<String>.from(data['photos'] ?? []),
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'score': score, 'photos': photos, 'notes': notes};
  }
}
