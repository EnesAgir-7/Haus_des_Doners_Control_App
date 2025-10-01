import 'package:cloud_firestore/cloud_firestore.dart';

class InspectionModel {
  final String id;
  final String branchId;
  final String branchName;
  final String inspectorId;
  final String inspectorName;
  final DateTime scheduledTime;
  final DateTime? completedTime;
  final String status; // "scheduled" | "completed" | "pending" | "current"
  final double score;
  final InspectionCategoryModel cleanlinessHygiene;
  final InspectionCategoryModel staffService;
  final InspectionCategoryModel productQuality;
  final String overallNotes;
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
    required this.cleanlinessHygiene,
    required this.staffService,
    required this.productQuality,
    required this.overallNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InspectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final categories = data['categories'] as Map<String, dynamic>;

    return InspectionModel(
      id: doc.id,
      branchId: data['branchId'] ?? '',
      branchName: data['branchName'] ?? '',
      inspectorId: data['inspectorId'] ?? '',
      inspectorName: data['inspectorName'] ?? '',
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      completedTime: data['completedTime'] != null
          ? (data['completedTime'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      score: (data['score'] ?? 0.0).toDouble(),
      cleanlinessHygiene: InspectionCategoryModel.fromMap(
        categories['cleanlinessHygiene'] ?? {},
      ),
      staffService: InspectionCategoryModel.fromMap(
        categories['staffService'] ?? {},
      ),
      productQuality: InspectionCategoryModel.fromMap(
        categories['productQuality'] ?? {},
      ),

      overallNotes: data['overallNotes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'completedTime': completedTime != null
          ? Timestamp.fromDate(completedTime!)
          : null,
      'status': status,
      'score': score,
      'categories': {
        'cleanlinessHygiene': cleanlinessHygiene.toMap(),
        'staffService': staffService.toMap(),
        'productQuality': productQuality.toMap(),
      },
      'overallNotes': overallNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isCurrent => status == 'current';
}

class InspectionCategoryModel {
  final int score; // 1-4 rating
  final List<String> photos;
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
