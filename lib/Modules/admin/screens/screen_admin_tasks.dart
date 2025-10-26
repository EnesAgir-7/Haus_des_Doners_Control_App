// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_tasks.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/core/extensions.dart';
import 'package:haus_des_control/models/task_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../widgets/task_detail_widget.dart';
import '../widgets/task_form_widget.dart';

class ScreenAdminTasks extends StatefulWidget {
  const ScreenAdminTasks({super.key});

  @override
  State<ScreenAdminTasks> createState() => _ScreenAdminTasksState();
}

class _ScreenAdminTasksState extends State<ScreenAdminTasks> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderTasks>().loadAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
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
          child: SafeArea(
            child: Consumer<ProviderTasks>(
              builder: (context, taskProvider, child) {
                final tasks = taskProvider.allTasks;
                final filteredTasks = _filterTasks(tasks);

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(taskProvider),
                      const SizedBox(height: 12),
                      // Removed top filter section
                      _buildTaskStats(tasks, clickable: true),
                      const SizedBox(height: 12),
                      Container(height: 1, color: Colors.white24),
                      const SizedBox(height: 12),
                      Expanded(
                        child: taskProvider.isLoading
                            ? _buildLoadingState()
                            : filteredTasks.isEmpty
                            ? _buildEmptyState(taskProvider)
                            : _buildTaskList(taskProvider, filteredTasks),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        floatingActionButton: _buildFAB(context),
      ),
    );
  }

  Widget _buildHeader(ProviderTasks provider) {
    return Row(
      children: [
        Icon(Icons.task_alt, color: Colors.lightBlueAccent),
        SizedBox(width: 6),
        Text(
          "Task Management",
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${provider.allTasks.length} Tasks",
            style: TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Updated _buildTaskStats to make stats clickable and include "All"
  Widget _buildTaskStats(List<TaskModel> tasks, {bool clickable = false}) {
    final Map<String, int> stats = {
      'all': tasks.length,
      'pending': tasks.where((t) => t.isPending).length,
      'in_progress': tasks.where((t) => t.isInProgress).length,
      'completed': tasks.where((t) => t.isCompleted).length,
      'overdue': tasks.where((t) => t.isOverdue).length,
    };

    final Map<String, Color> colors = {
      'all': Colors.grey,
      'pending': Colors.orange,
      'in_progress': Colors.blue,
      'completed': Colors.green,
      'overdue': Colors.red,
    };

    final Map<String, IconData> icons = {
      'all': Icons.list,
      'pending': Icons.pending_actions,
      'in_progress': Icons.trending_up,
      'completed': Icons.check_circle,
      'overdue': Icons.warning,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats.entries.map((entry) {
          final isSelected = _selectedFilter == entry.key;
          return GestureDetector(
            onTap: clickable
                ? () => setState(() => _selectedFilter = entry.key)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryRed : AppColors.lightBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primaryRed : Colors.white24,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryRed.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons[entry.key], color: colors[entry.key], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.key.replaceAll('_', ' ').capitalizeWords(),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    if (_selectedFilter == 'all') return tasks;
    return tasks.where((task) => task.status == _selectedFilter).toList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppColors.primaryRed),
    );
  }

  Widget _buildEmptyState(ProviderTasks provider) {
    return Center(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 80, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? 'No tasks available'
                  : 'No ${_selectedFilter.replaceAll('_', ' ')} tasks',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (_selectedFilter != 'all') ...[
              SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _selectedFilter = 'all'),
                child: Text(
                  'View all tasks',
                  style: TextStyle(color: AppColors.primaryRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(ProviderTasks provider, List<TaskModel> filteredTasks) {
    return RefreshIndicator(
      onRefresh: () => provider.loadAllTasks(),
      color: AppColors.primaryRed,
      backgroundColor: AppColors.lightBlack,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 80),
        key: const PageStorageKey('tasksList'),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: filteredTasks[index],
              onTap: () => _showTaskDetails(context, filteredTasks[index]),
              onEdit: () => _showTaskForm(context, filteredTasks[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "addTaskFab",
      onPressed: () => _showTaskForm(context, null),
      backgroundColor: AppColors.primaryRed,
      icon: Icon(Icons.add, color: Colors.white),
      label: Text(
        "Add Task",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBlack,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskDetailWidget(
        task: task,
        onTaskUpdated: () => context.read<ProviderTasks>().loadAllTasks(),
      ),
    );
  }

  void _showTaskForm(BuildContext context, TaskModel? task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskFormWidget(
        task: task,
        onSuccess: () => context.read<ProviderTasks>().loadAllTasks(),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onEdit, this.onTap});

  Color _getStatusColor() {
    switch (task.status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (task.status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon() {
    switch (task.status) {
      case 'pending':
        return Icons.pending_actions;
      case 'in_progress':
        return Icons.trending_up;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final priorityColor = _getPriorityColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, statusColor),
            const SizedBox(height: 12),
            _buildDescription(),
            const SizedBox(height: 12),
            _buildFooter(context, priorityColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color statusColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                task.assignedInspectorName,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getStatusIcon(), size: 14, color: Colors.grey.shade300),
              const SizedBox(width: 5),
              Text(
                _getStatusText(),
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_outlined,
            size: 18,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.description,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, Color priorityColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - Priority and Due Date
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag, size: 12, color: priorityColor),
                    const SizedBox(width: 4),
                    Text(
                      task.priority.toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (task.dueDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d').format(task.dueDate!),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Right side - Action Buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onEdit,

              child: Icon(
                Icons.edit,
                color: Colors.blue.withOpacity(0.7),
                size: 20,
              ),
            ),
            const SizedBox(width: 20),
            InkWell(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text(
                      'Are you sure you want to delete this task?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    final tasksProvider = context.read<ProviderTasks>();
                    final success = await tasksProvider.deleteTask(task.id);
                    if (success) {
                      showSnakBarr(context, "Task Deleted");
                    } else {
                      throw Exception('Failed to delete task');
                    }
                  } catch (e) {
                    showSnakBarr(context, 'Failed to delete task: $e');
                  }
                }
              },
              child: Icon(
                Icons.delete,
                color: Colors.red.withOpacity(0.7),
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
