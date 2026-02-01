import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../common_services/notification_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/branch_notification_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../../inspector/widgets/custom_field.dart';
import '../admin_providers/provider_admin_branch_notifications.dart';

class ScreenAdminBranchNotifications extends StatefulWidget {
  final String branchId;
  final String branchName;
  final List<String>? fcmTokens;

  const ScreenAdminBranchNotifications({
    super.key,
    required this.branchId,
    required this.branchName,
    this.fcmTokens,
  });

  @override
  State<ScreenAdminBranchNotifications> createState() =>
      _ScreenAdminBranchNotificationsState();
}

class _ScreenAdminBranchNotificationsState
    extends State<ScreenAdminBranchNotifications> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminBranchNotificationsProvider>();
      provider.loadNotificationsForBranch(widget.branchId);

      // Listen to search controller changes
      _searchController.addListener(() {
        provider.updateSearchQuery(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    return Scaffold(
      appBar: CustomAppBar(
        title: '${widget.branchName} - ${LocaleKeys.notifications.tr()}',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNotificationBottomSheet(context),
        label: const Text('Create Notification'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primaryRed,
      ),
      body: SafeArea(
        child: Consumer<AdminBranchNotificationsProvider>(
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

            final filtered = provider.getFilteredNotifications();
            final unseenCount = provider.getUnseenCount();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(filtered.length, unseenCount),
                        const SizedBox(height: 12),
                        _buildFilterChips(provider),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildNotificationCard(
                          context,
                          filtered[index],
                          provider,
                        ),
                      ),
                      childCount: filtered.length,
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
            'Error Loading Notifications',
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
            'No Notifications Yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first notification for this branch',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(int displayedCount, int unseenCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Branch Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$displayedCount ${displayedCount == 1 ? 'Notification' : 'Notifications'}${unseenCount > 0 ? ' • $unseenCount Unread' : ''}',
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
          const SizedBox(height: 12),
          Text(
            'All notifications sent to this branch',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          // Search field using CustomField
          CustomField(
            controller: _searchController,
            label: 'Search',
            hint: 'Search notifications...',
            icon: Icons.search,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AdminBranchNotificationsProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('All', provider),
        _buildFilterChip('Unread', provider),
        _buildFilterChip('Read', provider),
      ],
    );
  }

  Widget _buildFilterChip(
    String filter,
    AdminBranchNotificationsProvider provider,
  ) {
    final isSelected = provider.selectedFilter == filter;
    return ChoiceChip(
      label: Text(filter),
      selected: isSelected,
      onSelected: (_) => provider.updateFilter(filter),
      selectedColor: AppColors.primaryRed,
      backgroundColor: Colors.white.withValues(alpha: 0.03),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    BranchNotificationModel notification,
    AdminBranchNotificationsProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isSeen
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primaryRed.withValues(alpha: 0.3),
          width: notification.isSeen ? 1 : 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.isSeen),
              const SizedBox(width: 12),
              Expanded(child: _buildNotificationContent(notification)),
              _buildActionsMenu(context, notification, provider),
            ],
          ),
          const SizedBox(height: 12),
          _buildFooterTimestamps(notification),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(bool isSeen) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isSeen ? Colors.grey : AppColors.primaryRed).withValues(
          alpha: 0.2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isSeen ? Icons.notifications : Icons.notifications_active,
        size: 20,
        color: isSeen ? Colors.grey : AppColors.primaryRed,
      ),
    );
  }

  Widget _buildNotificationContent(BranchNotificationModel notification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!notification.isSeen) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryRed.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (notification.description.isNotEmpty)
          Text(
            notification.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 13,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildActionsMenu(
    BuildContext context,
    BranchNotificationModel notification,
    AdminBranchNotificationsProvider provider,
  ) {
    return PopupMenuButton<String>(
      color: AppColors.primaryDark,
      onSelected: (value) =>
          _handleMenuAction(context, value, notification, provider),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(LocaleKeys.edit.tr())),
        PopupMenuItem(value: 'copy', child: Text(LocaleKeys.copy.tr())),
        PopupMenuItem(value: 'delete', child: Text(LocaleKeys.delete.tr())),
      ],
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    BranchNotificationModel notification,
    AdminBranchNotificationsProvider provider,
  ) async {
    switch (action) {
      case 'edit':
        _showEditNotificationBottomSheet(context, notification);
        break;
      case 'copy':
        await Clipboard.setData(
          ClipboardData(
            text: '${notification.title}\n\n${notification.description}',
          ),
        );
        if (context.mounted) {
          showCustomSnackBar(context, 'Copied to clipboard');
        }
        break;
      case 'delete':
        final confirmed = await _showDeleteConfirmation(context);
        if (confirmed == true && context.mounted) {
          await provider.deleteNotification(notification.id, context: context);
        }
        break;
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Text(
          'Delete Notification',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this notification?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dc).pop(false),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dc).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterTimestamps(BranchNotificationModel notification) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (notification.createdAt != null)
          Text(
            DateFormat(
              'MMM dd, yyyy • hh:mm a',
            ).format(notification.createdAt!),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        if (notification.isSeen && notification.seenAt != null)
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.green.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Seen ${DateFormat('MMM dd').format(notification.seenAt!)}',
                style: TextStyle(
                  color: Colors.green.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _showAddNotificationBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _NotificationFormBottomSheet(
          title: 'Create Notification',
          branchName: widget.branchName,
          titleController: titleController,
          descriptionController: descriptionController,
          onSubmit: () async {
            final title = titleController.text.trim();
            final description = descriptionController.text.trim();

            if (title.isEmpty || description.isEmpty) {
              showSnakBarr(ctx, LocaleKeys.emptyFieldsMessage.tr());
              return;
            }

            final provider = context.read<AdminBranchNotificationsProvider>();
            Navigator.pop(ctx);

            final success = await provider.createNotification(
              title: title,
              description: description,
              branchId: widget.branchId,
              branchName: widget.branchName,
              context: context,
            );

            // Send FCM notification if tokens exist
            if (success &&
                widget.fcmTokens != null &&
                widget.fcmTokens!.isNotEmpty) {
              await NotificationHelper.instance
                  .sendNotificationToMultipleTokens(
                    title: title,
                    body: description,
                    fcmTokens: widget.fcmTokens!,
                    data: {
                      'type': 'branch_notification',
                      'branchId': widget.branchId,
                      'branchName': widget.branchName,
                      'timestamp': DateTime.now().toIso8601String(),
                    },
                  );
            }
          },
        ),
      ),
    );
  }

  void _showEditNotificationBottomSheet(
    BuildContext context,
    BranchNotificationModel notification,
  ) {
    final titleController = TextEditingController(text: notification.title);
    final descriptionController = TextEditingController(
      text: notification.description,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _NotificationFormBottomSheet(
          title: 'Edit Notification',
          branchName: widget.branchName,
          titleController: titleController,
          descriptionController: descriptionController,
          onSubmit: () async {
            final title = titleController.text.trim();
            final description = descriptionController.text.trim();

            if (title.isEmpty || description.isEmpty) {
              showSnakBarr(ctx, LocaleKeys.emptyFieldsMessage.tr());
              return;
            }

            final provider = context.read<AdminBranchNotificationsProvider>();
            Navigator.pop(ctx);

            final success = await provider.updateNotification(
              notificationId: notification.id,
              title: title,
              description: description,
              context: context,
            );

            // Send FCM notification if tokens exist
            if (success &&
                widget.fcmTokens != null &&
                widget.fcmTokens!.isNotEmpty) {
              await NotificationHelper.instance
                  .sendNotificationToMultipleTokens(
                    title: title,
                    body: description,
                    fcmTokens: widget.fcmTokens!,
                    data: {
                      'type': 'branch_notification_updated',
                      'branchId': widget.branchId,
                      'branchName': widget.branchName,
                      'timestamp': DateTime.now().toIso8601String(),
                    },
                  );
            }
          },
        ),
      ),
    );
  }
}

// Extracted bottom sheet widget for better code organization
class _NotificationFormBottomSheet extends StatelessWidget {
  final String title;
  final String branchName;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onSubmit;

  const _NotificationFormBottomSheet({
    required this.title,
    required this.branchName,
    required this.titleController,
    required this.descriptionController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBranchInfoCard(),
                  const SizedBox(height: 20),
                  CustomField(
                    controller: titleController,
                    label: LocaleKeys.title.tr(),
                    hint: 'Enter notification title',
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 16),
                  CustomField(
                    controller: descriptionController,
                    label: LocaleKeys.description.tr(),
                    hint: 'Enter notification description',
                    icon: Icons.message,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 24),
                  _buildActions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed.withValues(alpha: 0.15),
            AppColors.primaryRed.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              title.contains('Edit')
                  ? Icons.edit_notifications
                  : Icons.notifications_active,
              color: AppColors.primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchInfoCard() {
    return Container(
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
            child: const Icon(
              Icons.business,
              color: AppColors.primaryRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Branch',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  branchName,
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
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocaleKeys.cancelButton.tr()),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            title.contains('Edit') ? LocaleKeys.update.tr() : 'Create',
          ),
        ),
      ],
    );
  }
}
