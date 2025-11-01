// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:haus_des_control/models/task_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../common_services/user_selection_sheet.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../translations/locale_keys.g.dart';
import '../admin_providers/provider_admin_tasks.dart';

class TaskAddEditSheet extends StatefulWidget {
  final TaskModel? task; // null for create, TaskModel for update
  final VoidCallback? onSuccess;

  const TaskAddEditSheet({super.key, this.task, this.onSuccess});

  @override
  State<TaskAddEditSheet> createState() => _TaskAddEditSheetState();
}

class _TaskAddEditSheetState extends State<TaskAddEditSheet> {
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              surface: AppColors.lightBlack,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submitForm() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // Validation
    if (title.isEmpty) {
      showSnakBarr(context, LocaleKeys.pleaseEnterTitle.tr());
      return;
    }

    if (description.isEmpty) {
      showSnakBarr(context, LocaleKeys.pleaseEnterDescription.tr());
      return;
    }

    if (_selectedInspectorId == null) {
      showSnakBarr(context, LocaleKeys.pleaseSelectInspector.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tasksProvider = context.read<ProviderAdminTasks>();
      bool success;

      if (isUpdateMode) {
        // Update existing task
        final data = {
          TaskFields.title: title,
          TaskFields.description: description,
          TaskFields.assignedInspectorId: _selectedInspectorId,
          TaskFields.assignedInspectorName: _selectedInspectorName ?? '',
          TaskFields.priority: _priority,
          TaskFields.status: _status,
          TaskFields.dueDate: _dueDate != null
              ? Timestamp.fromDate(_dueDate!)
              : null,
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
        showSnakBarr(
          context,
          isUpdateMode
              ? LocaleKeys.taskUpdatedSuccess.tr()
              : LocaleKeys.taskCreatedSuccess.tr(),
        );
        widget.onSuccess?.call();
      } else {
        showSnakBarr(
          context,
          isUpdateMode
              ? LocaleKeys.failedToUpdateTask.tr()
              : LocaleKeys.failedToCreateTask.tr(),
        );
      }
    } catch (e) {
      showSnakBarr(context, '${LocaleKeys.error.tr()}: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFEF5350);
      case 'medium':
        return const Color(0xFFFFA726);
      case 'low':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      height: screenHeight,
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              isUpdateMode
                  ? LocaleKeys.editTask.tr()
                  : LocaleKeys.createTask.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  _buildInputField(
                    label: LocaleKeys.taskTitle.tr(),
                    controller: _titleController,
                    hint: LocaleKeys.enterTaskTitle.tr(),
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  _buildInputField(
                    label: LocaleKeys.description.tr(),
                    controller: _descriptionController,
                    hint: LocaleKeys.enterTaskDescription.tr(),
                    icon: Icons.description_rounded,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  // Priority Selection
                  Text(
                    LocaleKeys.priority.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPriorityChip(LocaleKeys.low.tr(), AppConstants.low),
                      const SizedBox(width: 8),
                      _buildPriorityChip(
                        LocaleKeys.medium.tr(),
                        AppConstants.medium,
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityChip(
                        LocaleKeys.high.tr(),
                        AppConstants.high,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Due Date
                  Text(
                    LocaleKeys.dueDateOptional.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickDueDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: _dueDate != null
                                ? AppColors.primaryRed
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _dueDate != null
                                ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                                : LocaleKeys.selectDueDate.tr(),
                            style: TextStyle(
                              color: _dueDate != null
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: _dueDate != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (_dueDate != null)
                            InkWell(
                              onTap: () => setState(() => _dueDate = null),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Assigned Inspector
                  Text(
                    LocaleKeys.assignedInspector.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final inspector = await showInspectorPicker(
                        context: context,
                        selectedInspectorId: _selectedInspectorId,
                      );

                      if (inspector != null) {
                        setState(() {
                          _selectedInspectorId = inspector.id;
                          _selectedInspectorName = inspector.name;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedInspectorId != null
                            ? AppColors.primaryRed.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedInspectorId != null
                              ? AppColors.primaryRed.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: _selectedInspectorId != null
                                ? AppColors.primaryRed.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                            child: Icon(
                              _selectedInspectorId != null
                                  ? Icons.person_rounded
                                  : Icons.person_add_rounded,
                              color: _selectedInspectorId != null
                                  ? AppColors.primaryRed
                                  : Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedInspectorName ??
                                  LocaleKeys.selectInspector.tr(),
                              style: TextStyle(
                                color: _selectedInspectorId != null
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                                fontWeight: _selectedInspectorId != null
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Status field (only for update mode)
                  if (isUpdateMode) ...[
                    const SizedBox(height: 20),
                    Text(
                      LocaleKeys.status.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatusChip(
                          LocaleKeys.pending.tr(),
                          AppConstants.pending,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          LocaleKeys.inProgress.tr(),
                          AppConstants.inProgress,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          LocaleKeys.completed.tr(),
                          AppConstants.completed,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white.withValues(
                              alpha: 0.9,
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            LocaleKeys.cancel.tr(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
                              : Text(
                                  isUpdateMode
                                      ? LocaleKeys.updateTask.tr()
                                      : LocaleKeys.createTask.tr(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
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
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String label, String value) {
    final isSelected = _priority == value;
    final color = _getPriorityColor(value);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag_rounded,
                size: 16,
                color: isSelected ? color : Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _status == value;
    Color color;
    switch (value) {
      case AppConstants.pending:
        color = const Color(0xFFFF9800);
        break;
      case AppConstants.inProgress:
        color = const Color(0xFF2196F3);
        break;
      case AppConstants.completed:
        color = const Color(0xFF4CAF50);
        break;
      default:
        color = Colors.grey;
    }

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
