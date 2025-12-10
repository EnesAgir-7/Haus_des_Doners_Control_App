import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';

class TrainingVideoModel {
  final String id;
  final String name;
  final String description;
  final String videoUrl;
  final DateTime createdAt;
  final String? branchId;

  TrainingVideoModel({
    required this.id,
    required this.name,
    required this.description,
    required this.videoUrl,
    required this.createdAt,
    this.branchId,
  });

  factory TrainingVideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final created = data[TrainingVideoFields.createdAt];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    } else {
      createdAt = DateTime.now();
    }

    return TrainingVideoModel(
      id: doc.id,
      name: data[TrainingVideoFields.name] ?? '',
      description: data[TrainingVideoFields.description] ?? '',
      videoUrl: data[TrainingVideoFields.videoUrl] ?? '',
      createdAt: createdAt,
      branchId: data[TrainingVideoFields.branchId] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      TrainingVideoFields.name: name,
      TrainingVideoFields.description: description,
      TrainingVideoFields.videoUrl: videoUrl,
      TrainingVideoFields.createdAt: createdAt,
    };

    if (branchId != null)
      map[TrainingVideoFields.branchId] = branchId as dynamic;

    return map;
  }
}
