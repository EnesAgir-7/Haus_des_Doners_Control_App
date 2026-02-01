import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/screens/screen_admin_announcements.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../branch_providers/provider_branch_dashboard.dart';
import '../branch_providers/provider_branch_notifications.dart';
import '../branch_providers/provider_branch_update_request.dart';
import 'screen_branch_request_edit.dart';
import 'screen_branch_trainings.dart';
import 'screen_branch_documents.dart';
import 'screen_notifications.dart';

class BranchScreenMore extends StatefulWidget {
  const BranchScreenMore({super.key});

  @override
  State<BranchScreenMore> createState() => Screen_BranchDashboardTabState();
}

class Screen_BranchDashboardTabState extends State<BranchScreenMore> {
  late ProviderBranchDashboard provider;

  @override
  void initState() {
    provider = context.read<ProviderBranchDashboard>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [_buildHeader(provider), _buildDashboardContent(provider)],
    );
  }

  Widget _buildHeader(ProviderBranchDashboard provider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryRed.withValues(alpha: 0.3),
              AppColors.primaryDark.withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.business,
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
                    provider.branchInfo?.name ??
                        LocaleKeys.branch_dashboard.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(ProviderBranchDashboard provider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 8),

          Text(
            LocaleKeys.quick_actions.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.select_action_to_continue.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),
          _buildActionsList(provider),

          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _buildActionsList(ProviderBranchDashboard provider) {
    // watch branch update request provider to show badge when there's a pending or rejected request
    final reqProv = context.watch<BranchUpdateRequestProvider>();
    final int updateBadge =
        (reqProv.hasPendingRequest || reqProv.rejectedCount > 0) ? 1 : 0;

    // watch notifications provider for unseen count
    final notifProv = context.watch<BranchNotificationsProvider>();
    final int notificationsBadge = notifProv.unseenCount;
    final actions = [
      {
        'icon': Icons.campaign_outlined,
        'label': LocaleKeys.announcements.tr(),
        'description': LocaleKeys.view_important_updates.tr(),
        'color': Colors.blue,
        'badge': 0, // Mock badge count
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const ScreenAdminAnnouncements(role: AppConstants.branch),
            ),
          );
        },
      },
      {
        'icon': Icons.notifications_outlined,
        'label': LocaleKeys.notifications.tr(),
        'description': 'Check your branch notifications',
        'color': Colors.orange,
        'badge': notificationsBadge,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenNotifications()),
          );
        },
      },
      {
        'icon': Icons.video_library_outlined,
        'label': LocaleKeys.training_videos.tr(),
        'description': LocaleKeys.access_training_materials.tr(),
        'color': AppColors.primaryRed,
        'badge': 0,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScreenBranchTrainings(branchId: loggedInUser!.id),
            ),
          );
        },
      },
      {
        'icon': Icons.folder_outlined,
        'label': LocaleKeys.documents.tr(),
        'description': LocaleKeys.browse_download_documents.tr(),
        'color': Colors.purple,
        'badge': 0,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScreenBranchDocuments(branchId: loggedInUser!.id),
            ),
          );
        },
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': LocaleKeys.update_request.tr(),
        'description': LocaleKeys.request_changes_updates.tr(),
        'color': Colors.teal,
        'badge': updateBadge,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ScreenBranchRequestEdit(branch: provider.branchInfo!),
            ),
          );
        },
      },
    ];

    return Column(
      children: actions.map((action) {
        return _buildActionItem(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          description: action['description'] as String,
          color: action['color'] as Color,
          badgeCount: action['badge'] as int,
          onTap: action['onTap'] as VoidCallback,
        );
      }).toList(),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
