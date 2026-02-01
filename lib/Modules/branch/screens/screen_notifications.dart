import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/branch_notification_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../branch_providers/provider_branch_notifications.dart';

class ScreenNotifications extends StatefulWidget {
  const ScreenNotifications({super.key});

  @override
  State<ScreenNotifications> createState() => _ScreenNotificationsState();
}

class _ScreenNotificationsState extends State<ScreenNotifications> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchId = loggedInUser?.id;
      if (branchId != null) {
        context.read<BranchNotificationsProvider>().loadNotificationsForBranch(
          branchId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    return Scaffold(
      appBar: CustomAppBar(title: LocaleKeys.notifications.tr()),
      body: SafeArea(
        child: Consumer<BranchNotificationsProvider>(
          builder: (context, provider, _) {
            // Loading State
            if (provider.isLoading && provider.notifications.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            }

            // Error State
            if (provider.errorMessage != null &&
                provider.notifications.isEmpty) {
              return _buildErrorState(provider.errorMessage!);
            }

            // Empty State
            if (provider.notifications.isEmpty) {
              return _buildEmptyState();
            }

            // Notifications List
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: 10,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildNotificationCard(
                          context,
                          provider.notifications[index],
                          provider,
                        ),
                      ),
                      childCount: provider.notifications.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading notifications',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications Available',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications from admins will appear here',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    BranchNotificationModel notification,
    BranchNotificationsProvider provider,
  ) {
    final unread = !notification.isSeen;

    return InkWell(
      onTap: () async {
        // Mark as seen when tapped
        if (unread) {
          await provider.markAsSeen(notification.id);
        }
        // Show notification details dialog
        if (context.mounted) {
          _showNotificationDetails(context, notification);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unread
                ? AppColors.primaryRed.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            width: unread ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(unread),
            const SizedBox(width: 12),
            Expanded(child: _buildNotificationContent(notification, unread)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(bool unread) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unread
            ? AppColors.primaryRed.withValues(alpha: 0.15)
            : AppColors.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        unread ? Icons.notifications_active : Icons.notifications,
        color: unread ? AppColors.primaryRed : Colors.white60,
        size: 20,
      ),
    );
  }

  Widget _buildNotificationContent(
    BranchNotificationModel notification,
    bool unread,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            if (unread)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(left: 8, right: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
            if (notification.createdAt != null)
              Text(
                _formatTime(notification.createdAt!),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          notification.description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  void _showNotificationDetails(
    BuildContext context,
    BranchNotificationModel notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              if (notification.createdAt != null)
                _buildInfoRow(
                  Icons.schedule,
                  DateFormat(
                    'MMM dd, yyyy • hh:mm a',
                  ).format(notification.createdAt!),
                ),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.person, 'From: ${notification.createdBy}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.closeButton.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
