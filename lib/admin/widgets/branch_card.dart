import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';
import '../../models/branch_model.dart';
import '../../translations/locale_keys.g.dart';
import '../screens/screen_admin_branch_details.dart';

class BranchCard extends StatelessWidget {
  final BranchModel branch;
  const BranchCard({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScreenAdminBranchDetails(branch: branch),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      branch.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(branch.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(branch.address, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInspectorInfo(branch.assignedInspector),
                  _buildLastInspectionInfo(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        text = 'Active';
        break;
      case 'inactive':
        color = Colors.grey;
        text = 'Inactive';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInspectorInfo(AssignedInspector? inspector) {
    return Row(
      children: [
        const Icon(Icons.person, size: 16, color: AppColors.primaryRed),
        const SizedBox(width: 4),
        Text(
          inspector?.name ?? LocaleKeys.unassigned.tr(),
          style: const TextStyle(fontSize: 14, color: AppColors.primaryRed),
        ),
      ],
    );
  }

  Widget _buildLastInspectionInfo() {
    if (branch.lastInspectionDate == null) {
      return const Text(
        'No inspection yet',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    return Row(
      children: [
        const Icon(Icons.history, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          branch.lastInspectionText,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (branch.lastInspectionScore != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getScoreColor(
                branch.lastInspectionScore!,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${branch.lastInspectionScore!.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(branch.lastInspectionScore!),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 9.0) return Colors.green;
    if (score >= 7.0) return Colors.orange;
    return Colors.red;
  }
}
