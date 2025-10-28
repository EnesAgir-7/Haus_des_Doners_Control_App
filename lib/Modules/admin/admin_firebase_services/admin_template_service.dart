import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../models/inspection_template_model.dart';

class TemplateHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _templatesCollection =>
      _firestore.collection(Collections.inspectionTemplates);

  /// Create a new template
  Future<String?> createQuestionnaire({
    required String name,
    required List<InspectionCategory> categories,
    required BuildContext context,
  }) async {
    try {
      final template = InspectionTemplate(
        id: '',
        name: name.trim(),
        categories: categories,
      );

      final docRef = await _templatesCollection.add(template.toMap());

      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Update an existing template
  Future<bool> updateQuestionnaire({
    required String templateId,
    required String name,
    required List<InspectionCategory> categories,
    required BuildContext context,
  }) async {
    try {
      final template = InspectionTemplate(
        id: templateId,
        name: name.trim(),
        categories: categories,
      );

      await _templatesCollection.doc(templateId).update(template.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTemplate({
    required String templateId,
    required BuildContext context,
  }) async {
    try {
      await _templatesCollection.doc(templateId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<InspectionTemplate>> templatesStream() {
    return _templatesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => InspectionTemplate.fromFirestore(doc))
          .toList();
    });
  }
}
