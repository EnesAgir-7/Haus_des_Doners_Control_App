import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../helpers/app_helpers.dart';
import '../../../models/branch_model.dart';
import '../../../translations/locale_keys.g.dart';
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
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0, 4),
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
      ],
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
                LocaleKeys.inspector.tr(),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.0),
              ),
              const Spacer(),
              Text(
                branch.assignedInspector?.name ?? LocaleKeys.unassigned.tr(),
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
                LocaleKeys.totalInspections.tr(),
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
            LocaleKeys.noInspectionYet.tr(),
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
        ? getScoreColor(branch.lastInspectionScore!)
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
                '${LocaleKeys.lastInspection.tr()}: ${branch.lastInspectionText}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
    String statusText;
    Color color;
    IconData icon;

    if (daysUntil == null) {
      // No scheduled date
      statusText = LocaleKeys.inRouteScheduledSoon.tr();
      color = Colors.blueAccent;
      icon = Icons.route;
    } else if (daysUntil < 0) {
      // Overdue
      statusText = LocaleKeys.daysOverdue.tr().replaceAll(
        '{days}',
        daysUntil.abs().toString(),
      );
      color = Colors.redAccent;
      icon = Icons.warning;
    } else if (daysUntil == 0) {
      // Today
      statusText = LocaleKeys.scheduledToday.tr();
      color = Colors.orangeAccent;
      icon = Icons.today;
    } else if (daysUntil == 1) {
      // Tomorrow
      statusText = LocaleKeys.tomorrow.tr();
      color = Colors.greenAccent;
      icon = Icons.schedule;
    } else if (daysUntil > 1 && daysUntil <= 7) {
      // In X days
      statusText = LocaleKeys.inDays.tr().replaceAll(
        '{days}',
        daysUntil.toString(),
      );
      color = Colors.greenAccent;
      icon = Icons.schedule;
    } else {
      // In weeks
      statusText = LocaleKeys.inWeeks.tr().replaceAll(
        '{weeks}',
        (daysUntil ~/ 7).toString(),
      );
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
            '${LocaleKeys.nextInspection.tr()}: $statusText',
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

  Color _getUrgencyColor(int days) {
    if (days == 0) return Colors.greenAccent;
    if (days <= 7) return Colors.greenAccent;
    if (days <= 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
