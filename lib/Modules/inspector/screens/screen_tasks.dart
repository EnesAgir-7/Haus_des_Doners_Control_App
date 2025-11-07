import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/task_model.dart';
import '../providers/provider_tasks.dart';
import '../widgets/inspector_task_details.dart';

class ScreenTasks extends StatefulWidget {
  @override
  _ScreenTasksState createState() => _ScreenTasksState();
}

class _ScreenTasksState extends State<ScreenTasks> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderTasks>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryRed.withValues(alpha: 0.08),
              AppColors.primaryDark,
              AppColors.primaryDark,
            ],
            stops: const [0.0, 0.25, 1.0],
          ),
        ),
        child: Consumer<ProviderTasks>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            }
            return Column(
              children: [
                // Filter chips
                _buildFilterSection(provider),

                // Task list
                Expanded(
                  child: provider.tasks.isEmpty
                      ? _buildEmptyState()
                      : _buildTaskList(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection(ProviderTasks provider) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.tasks.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: LocaleKeys.all.tr(),
                  count: provider.totalTasks,
                  isSelected: provider.statusFilter == AppConstants.all,
                  onTap: () => provider.setStatusFilter(AppConstants.all),
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: LocaleKeys.pending.tr(),
                  count: provider.pendingTasksCount,
                  isSelected: provider.statusFilter == AppConstants.pending,
                  onTap: () => provider.setStatusFilter(AppConstants.pending),
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: LocaleKeys.in_progress.tr(),
                  count: provider.inProgressTasksCount,
                  isSelected: provider.statusFilter == AppConstants.inProgress,
                  onTap: () =>
                      provider.setStatusFilter(AppConstants.inProgress),
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: LocaleKeys.completed.tr(),
                  count: provider.completedTasksCount,
                  isSelected: provider.statusFilter == AppConstants.completed,
                  onTap: () => provider.setStatusFilter(AppConstants.completed),
                ),
              ],
            ),
          ),

          if (provider.overdueTasksCount > 0) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryRed, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.primaryRed,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${provider.overdueTasksCount} ${LocaleKeys.tasks_overdue.tr()}',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : Color(0xFF3A3A3A),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFFB0B0B0),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFFB0B0B0),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(ProviderTasks provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AppColors.primaryRed,
      backgroundColor: Color(0xFF2A2A2A),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: provider.tasks.length,
        itemBuilder: (context, index) {
          final task = provider.tasks[index];
          return _buildTaskCard(task, provider);
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, ProviderTasks provider) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isOverdue
              ? AppColors.primaryRed.withValues(alpha: 0.5)
              : Color(0xFF3A3A3A),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTaskDetails(context, task, provider),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Priority indicator
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Task info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            task.description,
                            style: TextStyle(
                              color: Color(0xFF808080),
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    _buildStatusBadge(task.status),
                  ],
                ),

                SizedBox(height: 12),

                // Meta info
                Row(
                  children: [
                    if (task.dueDate != null) ...[
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: task.isOverdue
                            ? AppColors.primaryRed
                            : Color(0xFF808080),
                      ),
                      SizedBox(width: 6),
                      Text(
                        _formatDueDate(task.dueDate!),
                        style: TextStyle(
                          color: task.isOverdue
                              ? AppColors.primaryRed
                              : Color(0xFF808080),
                          fontSize: 12,
                          fontWeight: task.isOverdue
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      SizedBox(width: 16),
                    ],

                    if (task.relatedBranchId != null) ...[
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF808080),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          LocaleKeys.about_the_branch.tr(),
                          style: TextStyle(
                            color: Color(0xFF808080),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    if (task.comments.isNotEmpty) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.comment_outlined,
                        size: 14,
                        color: Color(0xFF808080),
                      ),
                      SizedBox(width: 4),
                      Text(
                        task.comments.length.toString(),
                        style: TextStyle(
                          color: Color(0xFF808080),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case AppConstants.completed:
        color = Color(0xFF4CAF50);
        text = LocaleKeys.completed.tr();
        icon = Icons.check_circle;
        break;
      case AppConstants.inProgress:
        color = Color(0xFFFFA726);
        text = LocaleKeys.in_progress.tr();
        icon = Icons.pending;
        break;
      case AppConstants.pending:
      default:
        color = Color(0xFF808080);
        text = LocaleKeys.pending.tr();
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case AppConstants.high:
        return AppColors.primaryRed;
      case AppConstants.medium:
        return Color(0xFFFFA726);
      case AppConstants.low:
      default:
        return Color(0xFF4CAF50);
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return '${LocaleKeys.days_ago.tr().replaceAll(AppConstants.count, difference.abs().toString())}';
    } else if (difference == 0) {
      return LocaleKeys.today.tr();
    } else if (difference == 1) {
      return LocaleKeys.tomorrow.tr();
    } else if (difference <= 7) {
      return '$difference ${LocaleKeys.days_left.tr()}';
    } else {
      return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Color(0xFF3A3A3A)),
          SizedBox(height: 16),
          Text(
            LocaleKeys.no_tasks_found.tr(),
            style: TextStyle(
              color: Color(0xFF808080),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            LocaleKeys.no_assigned_tasks.tr(),
            style: TextStyle(color: Color(0xFF606060), fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(
    BuildContext context,
    TaskModel task,
    ProviderTasks provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TaskDetailsSheet(task: task, provider: provider),
    );
  }
}
