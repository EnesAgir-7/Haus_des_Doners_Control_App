import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart'
    show showSnakBarr;

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../firebase_services/inspector_signature_service.dart';

Future<void> showAskToSaveSignatureDialog({
  required BuildContext context,
  required SignatureStorageService signatureStorage,
  required Uint8List inspectorSignature,
}) async {
  // Check if signature already saved
  final alreadySaved = await signatureStorage.hasSignature();
  if (alreadySaved) return; // Don't ask again if already saved

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.lightBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.draw, color: AppColors.primaryRed),
          const SizedBox(width: 12),
          Text(
            LocaleKeys.saveSignature.tr(),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.saveSignaturePrompt.tr(),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightRed,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocaleKeys.canRemoveLater.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            LocaleKeys.notNow.tr(),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
          ),
          child: Text(
            LocaleKeys.yesSaveIt.tr(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  if (shouldSave == true) {
    final success = await signatureStorage.saveSignature(inspectorSignature);

    if (success && context.mounted) {
      showSnakBarr(context, LocaleKeys.signatureSaved.tr());
    }
  }
}

Future<void> showDeleteSavedSignatureDialog({
  required BuildContext context,
  required SignatureStorageService signatureStorage,
  required VoidCallback
  onSignatureDeleted, // callback to clear local vars or update UI
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.lightBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          Text(
            LocaleKeys.deleteSavedSignature.tr(),
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.deleteSignatureWarning.tr(),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocaleKeys.actionCannotUndone.tr(),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            LocaleKeys.cancel.tr(),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Text(
            LocaleKeys.deletePermanently.tr(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final success = await signatureStorage.deleteSignature();

    if (success) {
      onSignatureDeleted(); // Perform UI/local cleanup

      if (context.mounted) {
        showSnakBarr(context, LocaleKeys.signatureDeleted.tr());
      }
    }
  }
}
