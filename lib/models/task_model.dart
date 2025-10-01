import 'package:cloud_firestore/cloud_firestore.dart';

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
    final commentsData = data['comments'] as List<dynamic>?;

    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedInspectorId: data['assignedInspectorId'] ?? '',
      assignedInspectorName: data['assignedInspectorName'] ?? '',
      relatedBranchId: data['relatedBranchId'],
      relatedInspectionId: data['relatedInspectionId'],
      status: data['status'] ?? 'pending',
      priority: data['priority'] ?? 'medium',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      comments:
          commentsData
              ?.map((c) => TaskCommentModel.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assignedInspectorId': assignedInspectorId,
      'assignedInspectorName': assignedInspectorName,
      'relatedBranchId': relatedBranchId,
      'relatedInspectionId': relatedInspectionId,
      'status': status,
      'priority': priority,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'comments': comments.map((c) => c.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

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
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;
  final List<String> photos;

  TaskCommentModel({
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
    required this.photos,
  });

  factory TaskCommentModel.fromMap(Map<String, dynamic> data) {
    return TaskCommentModel(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      photos: List<String>.from(data['photos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'photos': photos,
    };
  }
}
