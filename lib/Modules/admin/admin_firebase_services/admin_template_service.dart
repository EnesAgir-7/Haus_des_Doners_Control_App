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
  Future<String?> createTemplate({
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

  /// Read all templates
  Future<List<InspectionTemplate>> getAllTemplates() async {
    try {
      final querySnapshot = await _templatesCollection.get();

      return querySnapshot.docs
          .map((doc) => InspectionTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      return [];
    }
  }

  /// Read a single template by ID
  Future<InspectionTemplate?> getTemplateById(String templateId) async {
    try {
      final doc = await _templatesCollection.doc(templateId).get();

      if (doc.exists) {
        return InspectionTemplate.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching template: $e');
      return null;
    }
  }

  /// Update an existing template
  Future<bool> updateTemplate({
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

  /// Check if template name already exists
  Future<bool> isTemplateNameExists(String name, {String? excludeId}) async {
    try {
      final querySnapshot = await _templatesCollection
          .where(InspectionTemplateFields.name, isEqualTo: name.trim())
          .get();

      if (excludeId != null) {
        return querySnapshot.docs.any((doc) => doc.id != excludeId);
      }

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking template name: $e');
      return false;
    }
  }
}
