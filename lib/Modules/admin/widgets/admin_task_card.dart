import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../models/task_model.dart';
import '../../../translations/locale_keys.g.dart';

class AdminTaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const AdminTaskCard({super.key, required this.task, this.onEdit, this.onTap});

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
        return LocaleKeys.pending.tr();
      case 'in_progress':
        return LocaleKeys.inProgress.tr();
      case 'completed':
        return LocaleKeys.completed.tr();
      default:
        return LocaleKeys.unknown.tr();
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
        // Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     InkWell(
        //       onTap: onEdit,

        //       child: Icon(
        //         Icons.edit,
        //         color: Colors.blue.withValues(alpha: 0.7),
        //         size: 20,
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
