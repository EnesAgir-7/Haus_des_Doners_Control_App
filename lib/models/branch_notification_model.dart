import 'package:cloud_firestore/cloud_firestore.dart';

class BranchNotificationModel {
  final String id;
  final String title;
  final String description;
  final String branchId;
  final String branchName;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSeen;
  final DateTime? seenAt;

  BranchNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.branchId,
    required this.branchName,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isSeen = false,
    this.seenAt,
  });

  /// Create BranchNotificationModel from Firestore DocumentSnapshot
  factory BranchNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BranchNotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      branchId: data['branchId'] ?? '',
      branchName: data['branchName'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isSeen: data['isSeen'] ?? false,
      seenAt: (data['seenAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert BranchNotificationModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'branchId': branchId,
      'branchName': branchName,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isSeen': isSeen,
      'seenAt': seenAt != null ? Timestamp.fromDate(seenAt!) : null,
    };
  }

  /// Create a copy with modified fields
  BranchNotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    String? branchId,
    String? branchName,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSeen,
    DateTime? seenAt,
  }) {
    return BranchNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSeen: isSeen ?? this.isSeen,
      seenAt: seenAt ?? this.seenAt,
    );
  }
}
