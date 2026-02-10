import 'dart:io';
import 'dart:typed_data';

import 'package:haus_des_control/core/console.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for managing permanent file storage for draft reports
/// Stores images and signatures in app documents directory (persists across restarts)
class FileStorageService {
  /// Get the draft images directory (permanent storage)
  Future<Directory> _getDraftImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final draftsDir = Directory('${appDir.path}/draft_images');

    if (!await draftsDir.exists()) {
      await draftsDir.create(recursive: true);
    }

    return draftsDir;
  }

  /// Get the draft signatures directory (permanent storage)
  Future<Directory> _getDraftSignaturesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final signaturesDir = Directory('${appDir.path}/draft_signatures');

    if (!await signaturesDir.exists()) {
      await signaturesDir.create(recursive: true);
    }

    return signaturesDir;
  }

  /// Copy image to permanent app documents directory
  /// Returns the permanent file path
  Future<String> copyImageToPermanentStorage(File sourceFile) async {
    try {
      final draftsDir = await _getDraftImagesDirectory();

      // Generate unique filename with timestamp
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourceFile.path)}';
      final permanentPath = '${draftsDir.path}/$filename';

      // Copy file to permanent storage
      final permanentFile = await sourceFile.copy(permanentPath);

      console('✅ Copied image to permanent storage: $permanentPath');
      return permanentFile.path;
    } catch (e) {
      console('❌ Error copying image to permanent storage: $e');
      rethrow;
    }
  }

  /// Save signature as PNG file to permanent storage
  /// Returns the permanent file path
  Future<String> saveSignatureToPermanentStorage(
    Uint8List signatureBytes,
    String prefix,
  ) async {
    try {
      final signaturesDir = await _getDraftSignaturesDirectory();

      // Generate unique filename
      final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${signaturesDir.path}/$filename';

      // Save signature bytes as PNG file
      final file = File(filePath);
      await file.writeAsBytes(signatureBytes);

      console('✅ Saved signature to permanent storage: $filePath');
      return filePath;
    } catch (e) {
      console('❌ Error saving signature to permanent storage: $e');
      rethrow;
    }
  }

  /// Load signature from file path
  /// Returns null if file doesn't exist or error occurs
  Future<Uint8List?> loadSignatureFromFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        console('⚠️ Signature file not found: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      console('✅ Loaded signature from file: $filePath');
      return bytes;
    } catch (e) {
      console('❌ Error loading signature from file: $e');
      return null;
    }
  }

  /// Check if image file exists at given path
  Future<bool> imageExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete a single file
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        console('✅ Deleted file: $filePath');
      }
    } catch (e) {
      console('⚠️ Error deleting file: $e');
      // Don't throw - cleanup is best-effort
    }
  }

  /// Clean up all files associated with a draft
  Future<void> cleanupDraftFiles({
    List<String>? imagePaths,
    String? inspectorSignaturePath,
    String? branchSignaturePath,
  }) async {
    try {
      // Delete all image files
      if (imagePaths != null) {
        for (final imagePath in imagePaths) {
          await deleteFile(imagePath);
        }
      }

      // Delete signature files
      if (inspectorSignaturePath != null) {
        await deleteFile(inspectorSignaturePath);
      }

      if (branchSignaturePath != null) {
        await deleteFile(branchSignaturePath);
      }

      console('✅ Cleaned up draft files');
    } catch (e) {
      console('⚠️ Error during draft cleanup: $e');
      // Don't throw - cleanup is best-effort
    }
  }

  /// Clean up orphaned files (files not referenced by any draft)
  /// This is a maintenance operation, not required for normal use
  Future<void> cleanupOrphanedFiles(Set<String> referencedPaths) async {
    try {
      // Clean images directory
      final imagesDir = await _getDraftImagesDirectory();
      final imageFiles = await imagesDir.list().toList();

      for (final entity in imageFiles) {
        if (entity is File && !referencedPaths.contains(entity.path)) {
          await deleteFile(entity.path);
        }
      }

      // Clean signatures directory
      final signaturesDir = await _getDraftSignaturesDirectory();
      final signatureFiles = await signaturesDir.list().toList();

      for (final entity in signatureFiles) {
        if (entity is File && !referencedPaths.contains(entity.path)) {
          await deleteFile(entity.path);
        }
      }

      console('✅ Cleaned up orphaned files');
    } catch (e) {
      console('⚠️ Error cleaning up orphaned files: $e');
      // Don't throw - cleanup is best-effort
    }
  }
}
