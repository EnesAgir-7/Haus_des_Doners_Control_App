import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/models/draft_report.dart';
import 'package:haus_des_control/services/file_storage_service.dart';
import 'package:haus_des_control/common_services/crashlytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing draft report storage using Hive database
/// Provides CRUD operations and migration from SharedPreferences
class DraftStorageService {
  static const String _boxName = 'draft_reports';
  final FileStorageService _fileStorageService = FileStorageService();

  /// Initialize Hive and open the box
  /// Call this once at app startup
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DraftReportAdapter());
    }

    // Open the box
    await Hive.openBox<DraftReport>(_boxName);
  }

  /// Get the Hive box
  Box<DraftReport> _getBox() {
    return Hive.box<DraftReport>(_boxName);
  }

  /// Save draft report to Hive
  /// Returns true if successful
  Future<bool> saveDraft(DraftReport draft) async {
    try {
      final box = _getBox();

      // Update saved timestamp
      draft.savedAt = DateTime.now();

      // Save to Hive (uses branchId as key)
      await box.put(draft.branchId, draft);

      console('✅ Draft saved to Hive for branch: ${draft.branchId}');
      return true;
    } catch (e, st) {
      console('❌ Failed to save draft to Hive: $e');

      // Log to Crashlytics
      CrashlyticsService().logError(
        e,
        st,
        reason: 'Failed to save draft to Hive',
        context: {
          'branchId': draft.branchId,
          'photoCount': draft.photoPaths.values.fold(
            0,
            (sum, list) => sum + list.length,
          ),
        },
      );

      return false;
    }
  }

  /// Load draft report from Hive
  /// Returns null if no draft exists for the branch
  Future<DraftReport?> loadDraft(String branchId) async {
    try {
      final box = _getBox();
      final draft = box.get(branchId);

      if (draft != null) {
        console('✅ Draft loaded from Hive for branch: $branchId');

        // Validate that files still exist
        await _validateDraftFiles(draft);
      } else {
        console('ℹ️ No draft found in Hive for branch: $branchId');
      }

      return draft;
    } catch (e, st) {
      console('❌ Failed to load draft from Hive: $e');

      // Log to Crashlytics
      CrashlyticsService().logError(
        e,
        st,
        reason: 'Failed to load draft from Hive',
        context: {'branchId': branchId},
      );

      return null;
    }
  }

  /// Validate that all referenced files still exist
  /// Removes invalid file paths from draft
  Future<void> _validateDraftFiles(DraftReport draft) async {
    try {
      // Validate photo paths
      for (final categoryId in draft.photoPaths.keys.toList()) {
        final paths = draft.photoPaths[categoryId] ?? [];
        final validPaths = <String>[];

        for (final path in paths) {
          if (await _fileStorageService.imageExists(path)) {
            validPaths.add(path);
          } else {
            console('⚠️ Draft photo file missing: $path');
          }
        }

        if (validPaths.isEmpty) {
          draft.photoPaths.remove(categoryId);
        } else if (validPaths.length != paths.length) {
          draft.photoPaths[categoryId] = validPaths;
        }
      }

      // Validate inspector signature
      if (draft.inspectorSignaturePath != null) {
        if (!await _fileStorageService.imageExists(
          draft.inspectorSignaturePath!,
        )) {
          console(
            '⚠️ Inspector signature file missing: ${draft.inspectorSignaturePath}',
          );
          draft.inspectorSignaturePath = null;
        }
      }

      // Validate branch signature
      if (draft.branchSignaturePath != null) {
        if (!await _fileStorageService.imageExists(
          draft.branchSignaturePath!,
        )) {
          console(
            '⚠️ Branch signature file missing: ${draft.branchSignaturePath}',
          );
          draft.branchSignaturePath = null;
        }
      }

      // Save updated draft if any files were removed
      await draft.save();
    } catch (e) {
      console('⚠️ Error validating draft files: $e');
      // Don't throw - continue with potentially invalid paths
    }
  }

  /// Delete draft report and associated files
  Future<void> deleteDraft(String branchId) async {
    try {
      final box = _getBox();
      final draft = box.get(branchId);

      if (draft != null) {
        // Collect all file paths
        final allImagePaths = <String>[];
        for (final paths in draft.photoPaths.values) {
          allImagePaths.addAll(paths);
        }

        // Delete all associated files
        await _fileStorageService.cleanupDraftFiles(
          imagePaths: allImagePaths,
          inspectorSignaturePath: draft.inspectorSignaturePath,
          branchSignaturePath: draft.branchSignaturePath,
        );

        // Delete from Hive
        await box.delete(branchId);

        console('✅ Draft deleted for branch: $branchId');
      }
    } catch (e, st) {
      console('❌ Failed to delete draft: $e');

      // Log to Crashlytics
      CrashlyticsService().logError(
        e,
        st,
        reason: 'Failed to delete draft from Hive',
        context: {'branchId': branchId},
      );
    }
  }

  /// Get all draft reports
  Future<List<DraftReport>> getAllDrafts() async {
    try {
      final box = _getBox();
      return box.values.toList();
    } catch (e) {
      console('❌ Failed to get all drafts: $e');
      return [];
    }
  }

  /// Clean up drafts older than specified days
  Future<void> cleanupOldDrafts({int daysOld = 30}) async {
    try {
      final box = _getBox();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final draftsToDelete = <String>[];

      for (final draft in box.values) {
        if (draft.savedAt.isBefore(cutoffDate)) {
          draftsToDelete.add(draft.branchId);
        }
      }

      for (final branchId in draftsToDelete) {
        await deleteDraft(branchId);
        console('✅ Deleted old draft: $branchId');
      }

      if (draftsToDelete.isNotEmpty) {
        console('✅ Cleaned up ${draftsToDelete.length} old drafts');
      }
    } catch (e) {
      console('⚠️ Error cleaning up old drafts: $e');
    }
  }

  /// Migrate draft from SharedPreferences to Hive
  /// This is a one-time migration operation
  Future<void> migrateFromSharedPreferences(String branchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'draft_report_$branchId';
      final jsonData = prefs.getString(draftKey);

      if (jsonData == null) {
        console('ℹ️ No SharedPreferences draft to migrate for: $branchId');
        return;
      }

      console('🔄 Migrating draft from SharedPreferences to Hive...');

      final draftData = jsonDecode(jsonData) as Map<String, dynamic>;

      // Convert old format to new Hive model
      final scores =
          (draftData['scores'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {};

      final notes =
          (draftData['notes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ) ??
          {};

      final photoPaths =
          (draftData['photos'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>).map((e) => e as String).toList(),
            ),
          ) ??
          {};

      final enabledCategories =
          (draftData['enabledCategories'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          {};

      // Migrate signatures from base64 to files
      String? inspectorSigPath;
      String? branchSigPath;

      if (draftData['inspectorSignature'] != null) {
        try {
          final bytes = base64Decode(draftData['inspectorSignature'] as String);
          inspectorSigPath = await _fileStorageService
              .saveSignatureToPermanentStorage(bytes, 'inspector_sig');
        } catch (e) {
          console('⚠️ Failed to migrate inspector signature: $e');
        }
      }

      if (draftData['branchSignature'] != null) {
        try {
          final bytes = base64Decode(draftData['branchSignature'] as String);
          branchSigPath = await _fileStorageService
              .saveSignatureToPermanentStorage(bytes, 'branch_sig');
        } catch (e) {
          console('⚠️ Failed to migrate branch signature: $e');
        }
      }

      // Create Hive draft
      final draft = DraftReport(
        branchId: branchId,
        branchTemplateId: draftData['branchTemplateId'] as String? ?? '',
        scores: scores,
        notes: notes,
        photoPaths: photoPaths,
        inspectorSignaturePath: inspectorSigPath,
        branchSignaturePath: branchSigPath,
        overallNotes: draftData['overallNotes'] as String?,
        enabledCategories: enabledCategories,
        savedAt: DateTime.parse(
          draftData['savedAt'] as String? ?? DateTime.now().toIso8601String(),
        ),
        branchRepName: draftData['branchRepName'] as String?,
      );

      // Save to Hive
      await saveDraft(draft);

      // Clean up old SharedPreferences entry
      await prefs.remove(draftKey);

      console('✅ Successfully migrated draft from SharedPreferences to Hive');
    } catch (e, st) {
      console('❌ Failed to migrate draft from SharedPreferences: $e');

      // Log to Crashlytics but don't throw - migration is best-effort
      CrashlyticsService().logError(
        e,
        st,
        reason: 'Failed to migrate draft from SharedPreferences',
        context: {'branchId': branchId},
      );
    }
  }

  /// Close the Hive box (call before app shutdown if needed)
  Future<void> close() async {
    try {
      final box = _getBox();
      await box.close();
      console('✅ Draft storage service closed');
    } catch (e) {
      console('⚠️ Error closing draft storage service: $e');
    }
  }
}
