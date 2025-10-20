import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/task_model.dart';
import '../providers/provider_tasks.dart';

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
                child: CircularProgressIndicator(color: Color(0xFFE53935)),
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
                color: Color(0xFFE53935).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFE53935), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${provider.overdueTasksCount} ${LocaleKeys.tasks_overdue.tr()}',
                    style: TextStyle(
                      color: Color(0xFFE53935),
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
          color: isSelected ? Color(0xFFE53935) : Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFFE53935) : Color(0xFF3A3A3A),
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
      color: Color(0xFFE53935),
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
              ? Color(0xFFE53935).withValues(alpha: 0.5)
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
                            ? Color(0xFFE53935)
                            : Color(0xFF808080),
                      ),
                      SizedBox(width: 6),
                      Text(
                        _formatDueDate(task.dueDate!),
                        style: TextStyle(
                          color: task.isOverdue
                              ? Color(0xFFE53935)
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
        return Color(0xFFE53935);
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
            LocaleKeys.no_tasks_found.tr(),
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

// Task Details Bottom Sheet
class TaskDetailsSheet extends StatefulWidget {
  final TaskModel task;
  final ProviderTasks provider;

  TaskDetailsSheet({required this.task, required this.provider});

  @override
  State<TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<TaskDetailsSheet> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return AnimatedPadding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: viewInsets.bottom + 20,
          ),
          duration: Duration(milliseconds: 100),
          child: Column(
            children: [
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Title
                    Text(
                      widget.task.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Status and Priority
                    Row(
                      children: [
                        _buildDetailBadge(
                          icon: Icons.flag,
                          label: _getPriorityText(widget.task.priority),
                          color: _getPriorityColor(widget.task.priority),
                        ),
                        SizedBox(width: 12),
                        _buildDetailBadge(
                          icon: Icons.schedule,
                          label: _getStatusText(widget.task.status),
                          color: _getStatusColor(widget.task.status),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Description
                    Text(
                      LocaleKeys.description.tr(),
                      style: TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.task.description,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Meta info
                    if (widget.task.dueDate != null) ...[
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: LocaleKeys.due_date.tr(),
                        value:
                            '${widget.task.dueDate!.day}/${widget.task.dueDate!.month}/${widget.task.dueDate!.year}',
                      ),
                      SizedBox(height: 12),
                    ],

                    _buildInfoRow(
                      icon: Icons.person,
                      //TODO: locale
                      label: "Assigned Inspector",
                      value: widget.task.assignedInspectorName,
                    ),

                    SizedBox(height: 24),
                    Divider(color: Color(0xFF3A3A3A)),
                    SizedBox(height: 16),

                    // Comments section
                    _buildCommentsSection(),
                    SizedBox(height: 20),
                  ],
                ),
              ),

              // Fixed bottom section (Comment input and action buttons)
              if (!widget.task.isCompleted) ...[
                Divider(color: Color(0xFF3A3A3A), height: 1),
                SizedBox(height: 12),
                _buildCommentInputField(),
                SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.task.isPending)
                      Expanded(
                        child: _buildActionButton(
                          label: LocaleKeys.start.tr(),
                          icon: Icons.play_arrow,
                          color: Color(0xFFFFA726),
                          onPressed: () {
                            widget.provider.markAsInProgress(widget.task.id);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    if (widget.task.isInProgress) ...[
                      Expanded(
                        child: _buildActionButton(
                          label: LocaleKeys.complete.tr(),
                          icon: Icons.check_circle,
                          color: Color(0xFF4CAF50),
                          onPressed: () {
                            widget.provider.markAsCompleted(widget.task.id);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInputField() {
    return Consumer<ProviderTasks>(
      builder: (context, taskCont, child) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(0xFF3A3A3A), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: taskCont.commentController,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText:
                        "Add comment", // TODO: Add this to your locale keys
                    hintStyle: TextStyle(
                      color: Color(0xFF606060),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              Consumer<ProviderTasks>(
                builder: (context, tasks, child) {
                  return IconButton(
                    icon: Icon(Icons.send, color: Color(0xFFE53935)),
                    onPressed: tasks.isAddingComment
                        ? null
                        : () async {
                            // Add comment logic here
                            final TaskCommentModel? commnet = await widget
                                .provider
                                .addComment(widget.task.id, context);
                            if (commnet != null) {
                              FocusScope.of(context).unfocus();
                              widget.task.comments.add(commnet);
                            }
                          },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Color(0xFF808080)),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(color: Color(0xFF808080), fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    if (widget.task.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            LocaleKeys.no_comments.tr(),
            style: TextStyle(color: Color(0xFF606060), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: widget.task.comments.map((comment) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE53935),
                    child: Text(
                      comment.userName[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTimestamp(comment.timestamp),
                          style: TextStyle(
                            color: Color(0xFF606060),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (comment.text.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  comment.text,
                  style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 13),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case AppConstants.high:
        return Color(0xFFE53935);
      case AppConstants.medium:
        return Color(0xFFFFA726);
      case AppConstants.low:
      default:
        return Color(0xFF4CAF50);
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case AppConstants.high:
        return LocaleKeys.high.tr();
      case AppConstants.medium:
        return LocaleKeys.medium.tr();
      case AppConstants.low:
      default:
        return LocaleKeys.low.tr();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.completed:
        return Color(0xFF4CAF50);
      case AppConstants.inProgress:
        return Color(0xFFFFA726);
      case AppConstants.pending:
      default:
        return Color(0xFF808080);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.completed:
        return LocaleKeys.completed.tr();
      case AppConstants.inProgress:
        return LocaleKeys.in_progress.tr();
      case AppConstants.pending:
      default:
        return LocaleKeys.pending.tr();
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return LocaleKeys.just_now.tr();
    } else if (difference.inHours < 1) {
      return '"${LocaleKeys.minutes_ago.tr().replaceAll(AppConstants.count, difference.inMinutes.toString())}"';
    } else if (difference.inDays < 1) {
      return '"${LocaleKeys.hours_ago.tr().replaceAll(AppConstants.count, difference.inHours.toString())}"';
    } else if (difference.inDays < 7) {
      return '${LocaleKeys.days_ago.tr().replaceAll(AppConstants.count, difference.inDays.toString())}"';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
