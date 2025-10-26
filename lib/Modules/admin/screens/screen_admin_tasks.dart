// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_tasks.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/core/extensions.dart';
import 'package:haus_des_control/models/task_model.dart';
import 'package:provider/provider.dart';

import '../widgets/admin_task_card.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/task_add_edit_widget.dart';

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
            child: AdminTaskCard(
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
      builder: (context) => TaskDetailSheet(
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
      builder: (context) => TaskAddEditSheet(
        task: task,
        onSuccess: () => context.read<ProviderTasks>().loadAllTasks(),
      ),
    );
  }
}
