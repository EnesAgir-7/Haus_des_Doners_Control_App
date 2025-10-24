// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_tasks.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/models/task_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../admin_providers/provider_admin_users.dart';

class TaskFormWidget extends StatefulWidget {
  final TaskModel? task; // null for create, TaskModel for update
  final VoidCallback? onSuccess;

  const TaskFormWidget({super.key, this.task, this.onSuccess});

  @override
  State<TaskFormWidget> createState() => _TaskFormWidgetState();
}

class _TaskFormWidgetState extends State<TaskFormWidget> {
  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  // Form state
  String _priority = 'medium';
  DateTime? _dueDate;
  String? _selectedInspectorId;
  String? _selectedInspectorName;
  String _status = 'pending';

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    // If updating, populate form with existing data
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      _selectedInspectorId = widget.task!.assignedInspectorId;
      _selectedInspectorName = widget.task!.assignedInspectorName;
      _status = widget.task!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get isUpdateMode => widget.task != null;

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submitForm() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // Validation
    if (title.isEmpty || description.isEmpty) {
      _showSnackBar('Please fill in title and description');
      return;
    }

    if (_selectedInspectorId == null) {
      _showSnackBar('Please select an inspector');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tasksProvider = context.read<ProviderTasks>();
      bool success;

      if (isUpdateMode) {
        // Update existing task
        final data = {
          'title': title,
          'description': description,
          'assignedInspectorId': _selectedInspectorId,
          'assignedInspectorName': _selectedInspectorName ?? '',
          'priority': _priority,
          'status': _status,
          'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
        };

        success = await tasksProvider.updateTask(widget.task!.id, data);
      } else {
        // Create new task
        success = await tasksProvider.createTask(
          title: title,
          description: description,
          assignedInspectorId: _selectedInspectorId!,
          assignedInspectorName: _selectedInspectorName ?? '',
          priority: _priority,
          dueDate: _dueDate,
        );
      }

      if (success) {
        Navigator.pop(context);
        _showSnackBar(
          isUpdateMode
              ? 'Task updated successfully'
              : 'Task created successfully',
          isError: false,
        );
        widget.onSuccess?.call();
      } else {
        _showSnackBar(
          isUpdateMode ? 'Failed to update task' : 'Failed to create task',
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask() async {
    if (!isUpdateMode) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        final tasksProvider = context.read<ProviderTasks>();
        final success = await tasksProvider.deleteTask(widget.task!.id);

        if (success) {
          Navigator.pop(context);
          _showSnackBar('Task deleted successfully', isError: false);
          widget.onSuccess?.call();
        } else {
          _showSnackBar('Failed to delete task');
        }
      } catch (e) {
        _showSnackBar('Error deleting task: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height * 0.75;
    final inspectors = context.watch<ProviderAdminUsers>().inspectors;
    final adminUsersProvider = context.watch<ProviderAdminUsers>();

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
              isUpdateMode ? 'Update Task' : 'Create Task',
              style: const TextStyle(
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
                  // Title field
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

                  // Description field
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

                  // Priority and Due Date row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _priority,
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('Low')),
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
                                  ? DateFormat('yyyy-MM-dd').format(_dueDate!)
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

                  // Inspector selection
                  const Text(
                    'Assign to',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  if (adminUsersProvider.isLoading)
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
                            inspector.serviceAccount,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          activeColor: AppColors.primaryRed,
                        );
                      }).toList(),
                    ),

                  // Status field (only for update mode)
                  if (isUpdateMode) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Status',
                      style: TextStyle(color: Colors.white70),
                    ),
                    DropdownButtonFormField<String>(
                      value: _status,
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
                  ],

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(isUpdateMode ? 'Update' : 'Create'),
                      ),
                      if (isUpdateMode) ...[
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _deleteTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
