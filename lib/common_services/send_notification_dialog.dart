import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'notification_helper.dart';

/// Global method to show a notification dialog for any inspector
Future<void> showNotifyDialog({
  required BuildContext context,
  required String inspectorId,
  required String inspectorName,
  List<String>? fcmTokens,
}) async {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      final isLoggedOut = fcmTokens == null || fcmTokens.isEmpty;

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.lightBlack,
                AppColors.lightBlack.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isLoggedOut
                          ? Colors.orange.withValues(alpha: 0.15)
                          : AppColors.primaryRed.withValues(alpha: 0.15),
                      isLoggedOut
                          ? Colors.orange.withValues(alpha: 0.05)
                          : AppColors.primaryRed.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border(
                    left: BorderSide(
                      width: 4,
                      color: isLoggedOut ? Colors.orange : AppColors.primaryRed,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            (isLoggedOut ? Colors.orange : AppColors.primaryRed)
                                .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLoggedOut
                            ? Icons.info_outline
                            : Icons.notifications_active,
                        color: isLoggedOut
                            ? Colors.orange
                            : AppColors.primaryRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        LocaleKeys.sendNotificationTitle.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: isLoggedOut
                    ? _buildLoggedOutContent(inspectorName)
                    : _buildNotificationForm(
                        inspectorName,
                        titleController,
                        bodyController,
                      ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        isLoggedOut
                            ? LocaleKeys.closeButton.tr()
                            : LocaleKeys.cancelButton.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!isLoggedOut) ...[
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final title = titleController.text.trim();
                            final body = bodyController.text.trim();

                            if (title.isEmpty || body.isEmpty) {
                              showSnakBarr(
                                context,
                                LocaleKeys.emptyFieldsMessage.tr(),
                              );
                              return;
                            }

                            Navigator.pop(context);

                            final success = await NotificationHelper.instance
                                .sendToInspector(
                                  context: context,
                                  inspectorId: inspectorId,
                                  title: title,
                                  body: body,
                                  data: {
                                    'type': 'custom_notification',
                                    'inspectorId': inspectorId,
                                    'timestamp': DateTime.now()
                                        .toIso8601String(),
                                  },
                                  fcmTokens: fcmTokens,
                                );

                            if (success) {
                              showSnakBarr(
                                context,
                                LocaleKeys.notificationSentMessage.tr(
                                  namedArgs: {'inspectorName': inspectorName},
                                ),
                              );
                            } else {
                              showSnakBarr(
                                context,
                                LocaleKeys.notificationFailedMessage.tr(
                                  namedArgs: {'inspectorName': inspectorName},
                                ),
                              );
                            }
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryRed,
                                  AppColors.primaryRed.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryRed.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.send,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  LocaleKeys.sendButton.tr(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildLoggedOutContent(String inspectorName) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Warning Box
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocaleKeys.loggedOutMessage.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Inspector Info
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  LocaleKeys.inspector.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                inspectorName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                LocaleKeys.noFcmDescription.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildNotificationForm(
  String inspectorName,
  TextEditingController titleController,
  TextEditingController bodyController,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Inspector Info Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: AppColors.primaryRed, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.inspector.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inspectorName,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // Title Field
      TextField(
        controller: titleController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: LocaleKeys.titleLabel.tr(),
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.title,
            color: AppColors.primaryRed.withValues(alpha: 0.7),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primaryRed.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Body Field
      TextField(
        controller: bodyController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 4,
        decoration: InputDecoration(
          labelText: LocaleKeys.bodyLabel.tr(),
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Icon(
              Icons.message,
              color: AppColors.primaryRed.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primaryRed.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          alignLabelWithHint: true,
        ),
      ),
    ],
  );
}
