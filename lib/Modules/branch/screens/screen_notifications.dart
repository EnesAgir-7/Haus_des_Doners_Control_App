import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_app_bar.dart';

class ScreenNotifications extends StatelessWidget {
  const ScreenNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    return Scaffold(
      appBar: CustomAppBar(title: LocaleKeys.notifications.tr()),
      body: SafeArea(
        child: CustomScrollView(
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
                    child: _buildNotificationItem(context, index),
                  ),
                  childCount: 10,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, int index) {
    final unread = index % 3 == 0;

    final titles = [
      'Inspection Scheduled',
      'New Message',
      'Performance Update',
      'System Update',
      'Training Reminder',
      'Document Updated',
      'Score Published',
      'Task Assigned',
      'Alert Notice',
      'General Information',
    ];

    final messages = [
      'Your inspection is scheduled for tomorrow at 10:00 AM',
      'You have received a new message from the admin',
      'Your monthly performance score has been updated',
      'System maintenance scheduled for this weekend',
      'Complete your pending training modules by Friday',
      'Branch guidelines document has been updated',
      'Latest inspection score: 85% - Good performance',
      'New task assigned: Update contact information',
      'Please review the updated compliance requirements',
      'Check out the new features in the latest update',
    ];

    final icons = [
      Icons.calendar_today,
      Icons.message,
      Icons.trending_up,
      Icons.system_update,
      Icons.school,
      Icons.description,
      Icons.star,
      Icons.task_alt,
      Icons.warning_amber,
      Icons.info,
    ];

    final times = ['2m', '15m', '1h', '3h', '1d', '2d', '3d', '5d', '1w', '2w'];

    return Container(
      padding: const EdgeInsets.all(14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: unread
                  ? AppColors.primaryRed.withValues(alpha: 0.15)
                  : AppColors.primaryDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icons[index],
              color: unread ? AppColors.primaryRed : Colors.white60,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titles[index],
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
                    Text(
                      times[index],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  messages[index],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
