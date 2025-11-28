import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../branch_providers/provider_branch_dashboard.dart';
import 'screen_documents.dart';
import 'screen_notifications.dart';
import 'screen_trainings.dart';

class ScreenBranchDashboardTab extends StatefulWidget {
  const ScreenBranchDashboardTab({super.key});

  @override
  State<ScreenBranchDashboardTab> createState() =>
      Screen_BranchDashboardTabState();
}

class Screen_BranchDashboardTabState extends State<ScreenBranchDashboardTab> {
  late ProviderBranchDashboard provider;

  @override
  void initState() {
    provider = context.read<ProviderBranchDashboard>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.initialize();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: provider.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(provider),
          if (provider.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            )
          else if (provider.errorMessage != null)
            _buildErrorView(provider)
          else
            _buildDashboardContent(provider),
        ],
      ),
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

          const Text(
            "Quick Actions",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select an action to continue',
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
    final actions = [
      {
        'icon': Icons.campaign_outlined,
        'label': "Announcements",
        'description': 'View important updates and announcements',
        'color': Colors.blue,
        'badge': 3, // Mock badge count
        'onTap': () {
          // Navigate to announcements
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcements coming soon'),
              backgroundColor: AppColors.primaryRed,
            ),
          );
        },
      },
      {
        'icon': Icons.notifications_outlined,
        'label': LocaleKeys.notifications.tr(),
        'description': 'Check your latest notifications',
        'color': Colors.orange,
        'badge': provider.unreadNotifications,
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
        'description': 'Access training materials and videos',
        'color': AppColors.primaryRed,
        'badge': 0,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenTrainings()),
          );
        },
      },
      {
        'icon': Icons.folder_outlined,
        'label': LocaleKeys.documents.tr(),
        'description': 'Browse and download documents',
        'color': Colors.purple,
        'badge': 0,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenDocuments()),
          );
        },
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': LocaleKeys.update_request.tr(),
        'description': 'Request changes or updates',
        'color': Colors.teal,
        'badge': 0,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Update requests coming soon'),
              backgroundColor: AppColors.primaryRed,
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

  Widget _buildErrorView(ProviderBranchDashboard provider) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.primaryRed,
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.error_occurred.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: provider.refresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(LocaleKeys.retry.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
