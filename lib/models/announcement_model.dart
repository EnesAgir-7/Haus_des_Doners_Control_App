import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AnnouncementSeenInfo> seenBy;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.seenBy = const [],
  });

  /// Create AnnouncementModel from Firestore DocumentSnapshot
  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      seenBy:
          (data['seenBy'] as List?)
              ?.map((item) => AnnouncementSeenInfo.fromMap(item))
              .toList() ??
          [],
    );
  }

  /// Convert AnnouncementModel to Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'seenBy': seenBy.map((item) => item.toMap()).toList(),
    };
  }
}

class AnnouncementSeenInfo {
  final String branchId;
  final String branchName;
  final DateTime seenAt;

  AnnouncementSeenInfo({
    required this.branchId,
    required this.branchName,
    required this.seenAt,
  });

  factory AnnouncementSeenInfo.fromMap(Map<String, dynamic> map) {
    return AnnouncementSeenInfo(
      branchId: map['branchId'] ?? '',
      branchName: map['branchName'] ?? '',
      seenAt: (map['seenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'seenAt': Timestamp.fromDate(seenAt),
    };
  }
}
