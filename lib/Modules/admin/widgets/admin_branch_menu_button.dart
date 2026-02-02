import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../../common/menu_button.dart';

class BranchMenuButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSendNotification;
  final VoidCallback onUploadDocument;
  final VoidCallback onTrainingVideos;
  final VoidCallback onExport;
  final VoidCallback onRequestsHistory;

  const BranchMenuButton({
    Key? key,
    required this.onEdit,
    required this.onDelete,
    required this.onSendNotification,
    required this.onUploadDocument,
    required this.onTrainingVideos,
    required this.onExport,
    required this.onRequestsHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
      ),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      offset: const Offset(0, 50),

      itemBuilder: (context) => [
        buildMenuItem(
          value: 'edit',
          icon: Icons.edit_outlined,
          title: LocaleKeys.edit_branch.tr(),
          color: Colors.blue,
        ),
        buildDivider(),
        buildMenuItem(
          value: 'export',
          icon: Icons.file_download_outlined,
          title: LocaleKeys.export_excel.tr(),
          color: Colors.amber,
        ),
        buildDivider(),
        buildMenuItem(
          value: 'requests',
          icon: Icons.history_edu_outlined,
          title: LocaleKeys.request_history.tr(),
          color: Colors.orange,
        ),
        buildDivider(),
        buildMenuItem(
          value: 'notification',
          icon: Icons.notifications_active_outlined,
          title: LocaleKeys.send_notification.tr(),
          color: AppColors.primaryRed,
        ),
        buildDivider(),
        buildMenuItem(
          value: 'documents',
          icon: Icons.upload_file_outlined,
          title: LocaleKeys.documents.tr(),
          color: Colors.green,
        ),
        // buildDivider(),
        // buildMenuItem(
        //   value: 'training',
        //   icon: Icons.video_library_outlined,
        //   title: 'Training Videos',
        //   color: Colors.orange,
        // ),
        buildDivider(),
        buildMenuItem(
          value: 'delete',
          icon: Icons.delete_outline,
          title: LocaleKeys.delete_branch.tr(),
          color: Colors.red,
        ),
      ],

      // Handle selections
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'export':
            onExport();
            break;
          case 'delete':
            onDelete();
            break;
          case 'requests':
            onRequestsHistory();
            break;
          case 'notification':
            onSendNotification();
            break;
          case 'documents':
            onUploadDocument();
            break;
          case 'training':
            onTrainingVideos();
            break;
        }
      },
    );
  }
}
