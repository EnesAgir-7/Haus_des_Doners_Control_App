import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a single category/question inside a template
class InspectionCategory {
  final String categoryId;
  final String title;
  final int maxScore;

  InspectionCategory({
    required this.categoryId,
    required this.title,
    required this.maxScore,
  });

  // Factory to create a category from a map (from the Firestore array)
  factory InspectionCategory.fromMap(Map<String, dynamic> map) {
    return InspectionCategory(
      categoryId: map['categoryId'] ?? '',
      title: map['title'] ?? '',
      maxScore: map['maxScore'] ?? 4,
    );
  }
}

// Represents the main template document
class InspectionTemplate {
  final String id;
  final String name;
  final List<InspectionCategory> categories;

  InspectionTemplate({
    required this.id,
    required this.name,
    required this.categories,
  });

  factory InspectionTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert the list of maps from Firestore into a list of InspectionCategory objects
    final categoriesList =
        (data['categories'] as List<dynamic>?)
            ?.map(
              (categoryMap) => InspectionCategory.fromMap(
                categoryMap as Map<String, dynamic>,
              ),
            )
            .toList() ??
        [];

    return InspectionTemplate(
      id: doc.id,
      name: data['name'] ?? '',
      categories: categoriesList,
    );
  }
}
