import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/firebase_constants.dart';

class InspectionModel {
  final String id;
  final String branchId;
  final String branchName;
  final String inspectorId;
  final String? inspectorName;
  final String scheduledTime;
  final DateTime? completedTime;
  final String status; // "scheduled" | "completed" | "pending" | "current"
  final String score;
  final Map<String, InspectionCategoryModel> categories;
  final String overallNotes;
  final String? pdfReportUrl;
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

    final rawCategories =
        data[InspectionFields.categories] as Map<String, dynamic>? ?? {};

    final parsedCategories = rawCategories.map(
      (key, value) =>
          MapEntry(key, InspectionCategoryModel.fromMap(value ?? {})),
    );

    return InspectionModel(
      id: doc.id,
      branchId: data[InspectionFields.branchId] ?? '',
      branchName: data[InspectionFields.branchName] ?? '',
      inspectorId: data[InspectionFields.inspectorId] ?? '',
      inspectorName: data[InspectionFields.inspectorName],
      scheduledTime: data[InspectionFields.scheduledTime],
      completedTime: data[InspectionFields.completedTime] != null
          ? (data[InspectionFields.completedTime] as Timestamp).toDate()
          : null,
      status: data[InspectionFields.status] ?? AppConstants.pending,
      score: (data[InspectionFields.score] ?? "0/0").toString(),
      categories: parsedCategories,
      overallNotes: data[InspectionFields.overallNotes] ?? '',
      pdfReportUrl: data[InspectionFields.pdfReportUrl],
      createdAt: (data[InspectionFields.createdAt] as Timestamp).toDate(),
      updatedAt: (data[InspectionFields.updatedAt] as Timestamp).toDate(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      InspectionFields.branchId: branchId,
      InspectionFields.branchName: branchName,
      InspectionFields.inspectorId: inspectorId,
      InspectionFields.inspectorName: inspectorName,
      InspectionFields.scheduledTime: scheduledTime,
      InspectionFields.completedTime: completedTime != null
          ? Timestamp.fromDate(completedTime!)
          : null,
      InspectionFields.status: status,
      InspectionFields.score: score,
      InspectionFields.categories: categories.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      InspectionFields.pdfReportUrl: pdfReportUrl,
      InspectionFields.overallNotes: overallNotes,
      InspectionFields.createdAt: Timestamp.fromDate(createdAt),
      InspectionFields.updatedAt: Timestamp.fromDate(updatedAt),
    };
  }

  bool get isCompleted => status == AppConstants.completed;
  bool get isPending => status == AppConstants.pending;
  bool get isCurrent => status == AppConstants.current;
}

class InspectionCategoryModel {
  final String score;
  final List<String> photos;
  final String notes;

  InspectionCategoryModel({
    required this.score,
    required this.photos,
    required this.notes,
  });

  factory InspectionCategoryModel.fromMap(Map<String, dynamic> data) {
    return InspectionCategoryModel(
      score: data[InspectionFields.score] ?? "0/0",
      photos: List<String>.from(data[InspectionFields.photos] ?? []),
      notes: data[InspectionFields.notes] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      InspectionFields.score: score,
      InspectionFields.photos: photos,
      InspectionFields.notes: notes,
    };
  }
}
