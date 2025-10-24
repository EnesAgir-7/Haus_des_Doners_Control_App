// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_tasks.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/models/task_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../widgets/task_form_widget.dart';
import '../widgets/task_detail_widget.dart';

class ScreenAdminTasks extends StatefulWidget {
  const ScreenAdminTasks({super.key});

  @override
  State<ScreenAdminTasks> createState() => _ScreenAdminTasksState();
}

class _ScreenAdminTasksState extends State<ScreenAdminTasks> {
  String _selectedFilter = 'all'; // all, pending, in_progress, completed

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
      child: Consumer<ProviderTasks>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }

          final tasks = taskProvider.allTasks;
          final filteredTasks = _filterTasks(tasks);

          return Stack(
            children: [
              Column(
                children: [
                  _buildFilterSection(),
                  _buildTaskStats(tasks),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => taskProvider.loadAllTasks(),
                      color: AppColors.primaryRed,
                      backgroundColor: AppColors.lightBlack,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TaskCard(
                              task: filteredTasks[index],
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppColors.lightBlack,
                                  isScrollControlled: true,
                                  enableDrag: true,
                                  isDismissible: true,
                                  useSafeArea: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (context) => TaskDetailWidget(
                                    task: filteredTasks[index],
                                    onTaskUpdated: () {
                                      // Refresh tasks after update
                                      context
                                          .read<ProviderTasks>()
                                          .loadAllTasks();
                                    },
                                  ),
                                );
                              },
                              onEdit: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppColors.lightBlack,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (context) => TaskFormWidget(
                                    task: filteredTasks[index],
                                    onSuccess: () {
                                      // Refresh tasks after update
                                      context
                                          .read<ProviderTasks>()
                                          .loadAllTasks();
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.lightBlack,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) => TaskFormWidget(
                        onSuccess: () {
                          // Refresh tasks after create
                          context.read<ProviderTasks>().loadAllTasks();
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Task",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All Tasks'),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Pending'),
            const SizedBox(width: 8),
            _buildFilterChip('in_progress', 'In Progress'),
            const SizedBox(width: 8),
            _buildFilterChip('completed', 'Completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      backgroundColor: AppColors.lightBlack,
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryRed,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primaryRed
            : Colors.white.withValues(alpha: 0.7),
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.primaryRed
            : Colors.white.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildTaskStats(List<TaskModel> tasks) {
    final pendingCount = tasks.where((t) => t.isPending).length;
    final inProgressCount = tasks.where((t) => t.isInProgress).length;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final overdueCount = tasks.where((t) => t.isOverdue).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Pending',
            pendingCount,
            Colors.orange,
            Icons.pending_actions,
          ),
          _buildStatItem(
            'In Progress',
            inProgressCount,
            Colors.blue,
            Icons.trending_up,
          ),
          _buildStatItem(
            'Completed',
            completedCount,
            Colors.green,
            Icons.check_circle,
          ),
          _buildStatItem('Overdue', overdueCount, Colors.red, Icons.warning),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    if (_selectedFilter == 'all') return tasks;
    return tasks.where((task) => task.status == _selectedFilter).toList();
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.blue.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text(' '),
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
                            final success = await tasksProvider.deleteTask(
                              task.id,
                            );
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Task deleted')),
                              );
                            } else {
                              throw Exception('Failed to delete task');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete task: $e'),
                              ),
                            );
                          }
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.assignedInspectorName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
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
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(task.dueDate!),
                              style: const TextStyle(
                                color: Colors.purple,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
