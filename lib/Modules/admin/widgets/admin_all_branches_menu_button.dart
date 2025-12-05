import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import '../../common/menu_button.dart';

class BranchActionsMenuButton extends StatelessWidget {
  final VoidCallback onCreateAnnouncement;
  final VoidCallback onUpdateRequests;

  const BranchActionsMenuButton({
    Key? key,
    required this.onCreateAnnouncement,
    required this.onUpdateRequests,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(13),
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
          value: 'announcement',
          icon: Icons.campaign_outlined,
          title: 'Announcement',
          color: Colors.teal,
        ),
        buildDivider(),
        buildMenuItem(
          value: 'requests',
          icon: Icons.update_outlined,
          title: 'Update Requests',
          color: Colors.orange,
        ),
      ],

      onSelected: (value) {
        switch (value) {
          case 'announcement':
            onCreateAnnouncement();
            break;
          case 'requests':
            onUpdateRequests();
            break;
        }
      },
    );
  }
}
