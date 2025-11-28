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
              child: Center(child: CircularProgressIndicator()),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 28),
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
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(ProviderBranchDashboard provider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.branch_dashboard.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an action',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),

            // Clean, friendly grid with only the four requested actions
            _buildQuickActionsGrid(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(ProviderBranchDashboard provider) {
    final actions = [
      {
        'icon': Icons.notifications,
        'label': LocaleKeys.notifications.tr(),
        'subtitle': 'View your notifications',
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
        'icon': Icons.video_library,
        'label': LocaleKeys.training_videos.tr(),
        'subtitle': 'Learn and train',
        'color': Colors.red,
        'badge': 0,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenTrainings()),
          );
        },
      },
      {
        'icon': Icons.edit_note,
        'label': LocaleKeys.update_request.tr(),
        'subtitle': 'Request updates',
        'color': Colors.teal,
        'badge': 0,
        'onTap': () {
          // Navigate to update request
        },
      },
      {
        'icon': Icons.folder,
        'label': LocaleKeys.documents.tr(),
        'subtitle': 'Access documents',
        'color': Colors.purple,
        'badge': 0,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenDocuments()),
          );
        },
      },
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: actions.map((action) {
        return _buildActionCard(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          subtitle: action['subtitle'] as String,
          color: action['color'] as Color,
          badgeCount: action['badge'] as int,
          onTap: action['onTap'] as VoidCallback,
        );
      }).toList(),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const Spacer(),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(ProviderBranchDashboard provider) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.refresh,
              child: Text(LocaleKeys.retry.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
