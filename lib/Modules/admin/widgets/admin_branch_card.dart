import 'package:flutter/material.dart';

import '../../../models/branch_model.dart';
import '../screens/screen_admin_branch_details.dart';

class AdminBranchCard extends StatelessWidget {
  final BranchModel branch;
  const AdminBranchCard({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenAdminBranchDetails(branch: branch),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: _getPriorityColor().withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 14.0),
            _buildInspectorAndStats(),
            const SizedBox(height: 14.0),
            _buildLastInspectionInfo(),
            if (branch.stop != null) ...[
              const SizedBox(height: 12.0),
              _buildNextInspectionInfo(),
            ],
            if (branch.averageScore > 0) ...[
              const SizedBox(height: 12.0),
              _buildAverageScore(),
            ],
          ],
        ),
      ),
    );
  }

  /// Header: Branch name, region, and status
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.business, color: Colors.white, size: 24.0),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branch.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey.shade500,
                    size: 14.0,
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      branch.address,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (branch.region != null) ...[
                const SizedBox(height: 2.0),
                Text(
                  branch.region!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.0),
                ),
              ],
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        _getStatusText().toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Inspector and total inspections
  Widget _buildInspectorAndStats() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: branch.assignedInspector != null
                    ? Colors.grey.shade500
                    : Colors.grey.shade700,
                size: 16.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Assigned Inspector',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.0),
              ),
              const Spacer(),
              Text(
                branch.assignedInspector?.name ?? 'Unassigned',
                style: TextStyle(
                  color: branch.assignedInspector != null
                      ? Colors.white70
                      : Colors.grey.shade600,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: Colors.grey.shade500,
                size: 16.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Total Inspections',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.0),
              ),
              const Spacer(),
              Text(
                '${branch.totalInspections}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Last inspection details with score
  Widget _buildLastInspectionInfo() {
    if (branch.lastInspectionDate == null) {
      return Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18.0),
          const SizedBox(width: 8.0),
          Text(
            'No inspection yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13.0,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final days = branch.daysSinceLastInspection ?? 0;
    final urgencyColor = _getUrgencyColor(days);
    final scoreColor = branch.lastInspectionScore != null
        ? _getScoreColor(branch.lastInspectionScore!)
        : Colors.grey;

    return Row(
      children: [
        Icon(Icons.history, color: urgencyColor, size: 18.0),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Inspection: ${branch.lastInspectionText}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (days > 30) ...[
                const SizedBox(height: 2.0),
                Text(
                  '⚠️ Overdue by ${days - 30} days',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (branch.lastInspectionScore != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 5.0,
            ),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: scoreColor, width: 1),
            ),
            child: Text(
              branch.lastInspectionScore!,
              style: TextStyle(
                color: scoreColor,
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  /// Next inspection info (if scheduled)
  Widget _buildNextInspectionInfo() {
    final daysUntil = branch.daysUntilNextInspection;
    final isToday = branch.isNextInspectionToday;

    String statusText;
    Color color;
    IconData icon;

    if (isToday) {
      statusText = 'Scheduled TODAY';
      color = Colors.orangeAccent;
      icon = Icons.today;
    } else if (daysUntil == null) {
      statusText = 'In route - scheduled soon';
      color = Colors.blueAccent;
      icon = Icons.route;
    } else if (daysUntil < 0) {
      statusText = '${daysUntil.abs()} days overdue';
      color = Colors.redAccent;
      icon = Icons.warning;
    } else if (daysUntil == 0) {
      statusText = 'Due today';
      color = Colors.orangeAccent;
      icon = Icons.today;
    } else if (daysUntil == 1) {
      statusText = 'Tomorrow';
      color = Colors.greenAccent;
      icon = Icons.schedule;
    } else if (daysUntil <= 7) {
      statusText = 'In $daysUntil days';
      color = Colors.greenAccent;
      icon = Icons.schedule;
    } else {
      statusText = 'In ${(daysUntil / 7).ceil()} weeks';
      color = Colors.blueAccent;
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.0),
          const SizedBox(width: 8.0),
          Text(
            'Next Inspection: $statusText',
            style: TextStyle(
              color: color,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Average score display
  Widget _buildAverageScore() {
    final scoreColor = _getAverageScoreColor(branch.averageScore);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: scoreColor, size: 16.0),
          const SizedBox(width: 8.0),
          Text(
            'Average Performance',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12.0),
          ),
          const Spacer(),
          Text(
            '${branch.averageScore.toStringAsFixed(1)}%',
            style: TextStyle(
              color: scoreColor,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    if (branch.isNextInspectionToday) return Colors.orangeAccent;
    if (branch.daysSinceLastInspection != null &&
        branch.daysSinceLastInspection! > 30) {
      return Colors.redAccent;
    }
    return _getStatusColor();
  }

  Color _getStatusColor() {
    switch (branch.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (branch.status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'pending':
        return 'Pending';
      default:
        return branch.status;
    }
  }

  Color _getUrgencyColor(int days) {
    if (days == 0) return Colors.greenAccent;
    if (days <= 7) return Colors.greenAccent;
    if (days <= 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getScoreColor(String scoreString) {
    final parts = scoreString.split('/');
    if (parts.length != 2) return Colors.grey;

    final score = double.tryParse(parts.first) ?? 0.0;
    final maxScore = double.tryParse(parts.last) ?? 1.0;
    final percentage = (score / maxScore) * 100;

    if (percentage >= 80) return Colors.greenAccent;
    if (percentage >= 60) return Colors.yellowAccent;
    if (percentage >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getAverageScoreColor(double percentage) {
    if (percentage >= 80) return Colors.greenAccent;
    if (percentage >= 60) return Colors.yellowAccent;
    if (percentage >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
