import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';

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
      categoryId: map[InspectionCategoryFields.categoryId] ?? '',
      title: map[InspectionCategoryFields.title] ?? '',
      maxScore: map[InspectionCategoryFields.maxScore] ?? 4,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      InspectionCategoryFields.categoryId: categoryId,
      InspectionCategoryFields.title: title,
      InspectionCategoryFields.maxScore: maxScore,
    };
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

    final categoriesList =
        (data[InspectionTemplateFields.categories] as List<dynamic>?)
            ?.map(
              (categoryMap) => InspectionCategory.fromMap(
                categoryMap as Map<String, dynamic>,
              ),
            )
            .toList() ??
        [];

    return InspectionTemplate(
      id: doc.id,
      name: data[InspectionTemplateFields.name] ?? '',
      categories: categoriesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      InspectionTemplateFields.name: name,
      InspectionTemplateFields.categories: categories
          .map((e) => e.toMap())
          .toList(),
    };
  }
}
