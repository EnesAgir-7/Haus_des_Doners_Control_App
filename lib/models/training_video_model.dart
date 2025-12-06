import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';

class TrainingVideoModel {
  final String id;
  final String branchId;
  final String name;
  final String description;
  final String videoUrl;
  final DateTime createdAt;

  TrainingVideoModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.description,
    required this.videoUrl,
    required this.createdAt,
  });

  factory TrainingVideoModel.fromFirestore(
    DocumentSnapshot doc,
    String branchId, // Pass branchId since it's not in the document
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainingVideoModel(
      id: doc.id,
      branchId: branchId, // Use the passed branchId
      name: data[TrainingVideoFields.name] ?? '',
      description: data[TrainingVideoFields.description] ?? '',
      videoUrl: data[TrainingVideoFields.videoUrl] ?? '',
      createdAt: (data[TrainingVideoFields.createdAt] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Don't include branchId in the map since it's in the path
      TrainingVideoFields.name: name,
      TrainingVideoFields.description: description,
      TrainingVideoFields.videoUrl: videoUrl,
      TrainingVideoFields.createdAt: createdAt,
    };
  }
}
