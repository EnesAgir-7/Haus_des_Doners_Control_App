import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';

import '../core/constants/firebase_constants.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedInspectorId;
  final String assignedInspectorName;
  final String? relatedBranchId;
  final String? relatedInspectionId;
  final String status; // "pending" | "in_progress" | "completed"
  final String priority; // "low" | "medium" | "high"
  final DateTime? dueDate;
  final List<TaskCommentModel> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedInspectorId,
    required this.assignedInspectorName,
    this.relatedBranchId,
    this.relatedInspectionId,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final commentsData = data[TaskFields.comments] as List<dynamic>?;

    return TaskModel(
      id: doc.id,
      title: data[TaskFields.title] ?? '',
      description: data[TaskFields.description] ?? '',
      assignedInspectorId: data[TaskFields.assignedInspectorId] ?? '',
      assignedInspectorName: data[TaskFields.assignedInspectorName] ?? '',
      relatedBranchId: data[TaskFields.relatedBranchId],
      relatedInspectionId: data[TaskFields.relatedInspectionId],
      status: data[TaskFields.status] ?? AppConstants.pending,
      priority: data[TaskFields.priority] ?? AppConstants.medium,
      dueDate: data[TaskFields.dueDate] != null
          ? (data[TaskFields.dueDate] as Timestamp).toDate()
          : null,
      comments:
          commentsData?.asMap().entries.map((entry) {
            final commentMap = entry.value as Map<String, dynamic>;
            final commentId =
                commentMap[TaskCommentFields.id] ??
                'comment_${entry.key}_${DateTime.now().millisecondsSinceEpoch}';
            return TaskCommentModel.fromMap(commentMap, id: commentId);
          }).toList() ??
          [],
      createdAt: (data[TaskFields.createdAt] as Timestamp).toDate(),
      updatedAt: (data[TaskFields.updatedAt] as Timestamp).toDate(),
    );
  }
   /// ✅ CopyWith method
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedInspectorId,
    String? assignedInspectorName,
    String? relatedBranchId,
    String? relatedInspectionId,
    String? status,
    String? priority,
    DateTime? dueDate,
    List<TaskCommentModel>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedInspectorId: assignedInspectorId ?? this.assignedInspectorId,
      assignedInspectorName:
          assignedInspectorName ?? this.assignedInspectorName,
      relatedBranchId: relatedBranchId ?? this.relatedBranchId,
      relatedInspectionId: relatedInspectionId ?? this.relatedInspectionId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      TaskFields.title: title,
      TaskFields.description: description,
      TaskFields.assignedInspectorId: assignedInspectorId,
      TaskFields.assignedInspectorName: assignedInspectorName,
      TaskFields.relatedBranchId: relatedBranchId,
      TaskFields.relatedInspectionId: relatedInspectionId,
      TaskFields.status: status,
      TaskFields.priority: priority,
      TaskFields.dueDate: dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      TaskFields.comments: comments.map((c) => c.toMap()).toList(),
      TaskFields.createdAt: Timestamp.fromDate(createdAt),
      TaskFields.updatedAt: Timestamp.fromDate(updatedAt),
    };
  }

  bool get isPending => status == AppConstants.pending;
  bool get isInProgress => status == AppConstants.inProgress;
  bool get isCompleted => status == AppConstants.completed;

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }
}

class TaskCommentModel {
  final String id; // ADD THIS
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;
  final List<String> photos;

  TaskCommentModel({
    required this.id, // ADD THIS
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
    required this.photos,
  });

  factory TaskCommentModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return TaskCommentModel(
      id: id ?? data[TaskCommentFields.id] ?? '', // ADD THIS
      userId: data[TaskCommentFields.userId] ?? '',
      userName: data[TaskCommentFields.userName] ?? '',
      text: data[TaskCommentFields.text] ?? '',
      timestamp: (data[TaskCommentFields.timestamp] as Timestamp).toDate(),
      photos: List<String>.from(data[TaskCommentFields.photos] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      TaskCommentFields.id: id, // ADD THIS
      TaskCommentFields.userId: userId,
      TaskCommentFields.userName: userName,
      TaskCommentFields.text: text,
      TaskCommentFields.timestamp: Timestamp.fromDate(timestamp),
      TaskCommentFields.photos: photos,
    };
  }
}
