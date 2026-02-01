import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../helpers/app_helpers.dart';
import '../../models/document_model.dart';
import '../../translations/locale_keys.g.dart';

// Add this method to your ScreenAdminDocumentsScreen class

Future<void> openDocument(BuildContext context, DocumentModel doc) async {
  try {
    final uri = Uri.parse(doc.fileUrl);

    // Try to launch the URL
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Opens in external app/browser
      );
    } else {
      if (context.mounted) {
        showSnakBarr(
          context,
          "${LocaleKeys.could_not_open_document.tr()} ${doc.fileName}",
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      showSnakBarr(context, "${LocaleKeys.error_opening_document.tr()}$e");
    }
  }
}

// Alternative: Show a dialog with options
Future<void> showDocumentOptions(
  BuildContext context,
  DocumentModel doc,
) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Document info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getFileIcon(doc.fileExtension),
                      color: AppColors.primaryRed,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc.fileName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white12, height: 1),

            // Options
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Colors.white),
              title: Text(
                LocaleKeys.open_document.tr(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                openDocument(context, doc);
              },
            ),

            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: Text(
                LocaleKeys.copy_link.tr(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                copyLink(context, doc.fileUrl);
              },
            ),

            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: Text(
                LocaleKeys.share.tr(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                shareDocument(context, doc);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

// Copy link to clipboard
Future<void> copyLink(BuildContext context, String url) async {
  try {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      showSnakBarr(context, LocaleKeys.copied.tr());
    }
  } catch (e) {
    if (context.mounted) {
      showSnakBarr(context, e.toString());
    }
  }
}

// Share document (requires share_plus package)
Future<void> shareDocument(BuildContext context, DocumentModel doc) async {
  try {
    await SharePlus.instance.share(
      ShareParams(text: doc.fileUrl, subject: doc.name),
    );
  } catch (e) {
    if (context.mounted) {
      showSnakBarr(context, e.toString());
    }
  }
}
