// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/models/task_model.dart';
import 'package:haus_des_control/providers/provider_tasks.dart';
import 'package:provider/provider.dart';
import '../../providers/provider_auth.dart';
import 'package:intl/intl.dart';

import '../admin_providers/provider_admin_users.dart';

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
    return Consumer<ProviderTasks>(
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
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                builder: (context) => _buildUpdateTaskWidget(
                                  filteredTasks[index],
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
                    builder: (context) {
                      return _buildCreateTaskWidget();
                    },
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
    );
  }

  Widget _buildUpdateTaskWidget(TaskModel task) {
    final screenHeight = MediaQuery.of(context).size.height * 0.75;

    final _titleController = TextEditingController(text: task.title);
    final _descriptionController = TextEditingController(
      text: task.description,
    );
    String _priority = task.priority;
    DateTime? _dueDate = task.dueDate;
    String? _selectedInspectorId = task.assignedInspectorId;
    String? _selectedInspectorName = task.assignedInspectorName;
    String _status = task.status;

    // Ensure inspectors loaded
    final adminUsersProvider = context.read<ProviderAdminUsers>();
    if (!adminUsersProvider.isLoading && adminUsersProvider.users.isEmpty) {
      final currentUserId = context.read<ProviderAuth>().currentUser?.uid ?? '';
      adminUsersProvider.loadUsers(currentUserId);
    }

    return StatefulBuilder(
      builder: (context, setState) {
        final inspectors = context.watch<ProviderAdminUsers>().inspectors;
        final tasksProvider = context.read<ProviderTasks>();

        Future<void> _pickDueDate() async {
          final picked = await showDatePicker(
            context: context,
            initialDate:
                _dueDate ?? DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) setState(() => _dueDate = picked);
        }

        return Container(
          height: screenHeight * 0.95,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Update Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          filled: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          filled: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _priority,
                              items: const [
                                DropdownMenuItem(
                                  value: 'low',
                                  child: Text('Low'),
                                ),
                                DropdownMenuItem(
                                  value: 'medium',
                                  child: Text('Medium'),
                                ),
                                DropdownMenuItem(
                                  value: 'high',
                                  child: Text('High'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _priority = v);
                              },
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                filled: true,
                              ),
                              dropdownColor: AppColors.lightBlack,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _pickDueDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Due date',
                                  filled: true,
                                ),
                                child: Text(
                                  _dueDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_dueDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _dueDate != null
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Assign to',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      if (context.watch<ProviderAdminUsers>().isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (inspectors.isEmpty)
                        const Text(
                          'No inspectors available',
                          style: TextStyle(color: Colors.white70),
                        )
                      else
                        Column(
                          children: inspectors.map((inspector) {
                            return RadioListTile<String>(
                              value: inspector.id,

                              groupValue: _selectedInspectorId,
                              onChanged: (v) {
                                setState(() {
                                  _selectedInspectorId = v;
                                  _selectedInspectorName = inspector.name;
                                });
                              },
                              title: Text(
                                inspector.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                inspector.email,
                                style: TextStyle(color: Colors.white70),
                              ),
                              activeColor: AppColors.primaryRed,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Status',
                        style: TextStyle(color: Colors.white70),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        items: const [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('In Progress'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completed'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          filled: true,
                        ),
                        dropdownColor: AppColors.lightBlack,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final title = _titleController.text.trim();
                              final description = _descriptionController.text
                                  .trim();

                              if (title.isEmpty ||
                                  description.isEmpty ||
                                  _selectedInspectorId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill title, description and assign an inspector',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final data = {
                                'title': title,
                                'description': description,
                                'assignedInspectorId': _selectedInspectorId,
                                'assignedInspectorName':
                                    _selectedInspectorName ?? '',
                                'priority': _priority,
                                'status': _status,
                                'dueDate': _dueDate != null
                                    ? Timestamp.fromDate(_dueDate!)
                                    : null,
                              };

                              final success = await tasksProvider.updateTask(
                                task.id,
                                data,
                              );

                              if (success) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Task updated')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update task'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                            ),
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateTaskWidget() {
    // Build a form to create a new task and assign it to an inspector
    final screenHeight = MediaQuery.of(context).size.height * 0.75;

    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    String _priority = 'medium';
    DateTime? _dueDate;
    String? _selectedInspectorId;
    String? _selectedInspectorName;

    // Load inspectors list from ProviderAdminUsers
    final adminUsersProvider = context.read<ProviderAdminUsers>();
    if (!adminUsersProvider.isLoading && adminUsersProvider.users.isEmpty) {
      // attempt to load users if not loaded yet
      final currentUserId = context.read<ProviderAuth>().currentUser?.uid ?? '';
      adminUsersProvider.loadUsers(currentUserId);
    }

    return StatefulBuilder(
      builder: (context, setState) {
        final inspectors = context.watch<ProviderAdminUsers>().inspectors;
        final tasksProvider = context.read<ProviderTasks>();

        Future<void> _pickDueDate() async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) setState(() => _dueDate = picked);
        }

        return Container(
          height: screenHeight * 0.95,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Create Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _priority,
                              items: const [
                                DropdownMenuItem(
                                  value: 'low',
                                  child: Text('Low'),
                                ),
                                DropdownMenuItem(
                                  value: 'medium',
                                  child: Text('Medium'),
                                ),
                                DropdownMenuItem(
                                  value: 'high',
                                  child: Text('High'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _priority = v);
                              },
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                filled: true,
                              ),
                              dropdownColor: AppColors.lightBlack,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _pickDueDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Due date',
                                  filled: true,
                                ),
                                child: Text(
                                  _dueDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_dueDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _dueDate != null
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Assign to',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      if (context.watch<ProviderAdminUsers>().isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (inspectors.isEmpty)
                        const Text(
                          'No inspectors available',
                          style: TextStyle(color: Colors.white70),
                        )
                      else
                        Column(
                          children: inspectors.map((inspector) {
                            return RadioListTile<String>(
                              value: inspector.id,
                              groupValue: _selectedInspectorId,
                              onChanged: (v) {
                                setState(() {
                                  _selectedInspectorId = v;
                                  _selectedInspectorName = inspector.name;
                                });
                              },
                              title: Text(
                                inspector.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                inspector.email,
                                style: TextStyle(color: Colors.white70),
                              ),
                              activeColor: AppColors.primaryRed,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final title = _titleController.text.trim();
                              final description = _descriptionController.text
                                  .trim();

                              if (title.isEmpty ||
                                  description.isEmpty ||
                                  _selectedInspectorId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill title, description and assign an inspector',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final success = await tasksProvider.createTask(
                                title: title,
                                description: description,
                                assignedInspectorId: _selectedInspectorId!,
                                assignedInspectorName:
                                    _selectedInspectorName ?? '',
                                priority: _priority,
                                dueDate: _dueDate,
                              );

                              if (success) {
                                Navigator.pop(context);
                                // Optionally show success
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Task created')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to create task'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                            ),
                            child: const Text('Create'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

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
