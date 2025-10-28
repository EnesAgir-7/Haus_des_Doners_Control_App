import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/helpers/app_helpers.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/branch_model.dart';
import '../../../translations/locale_keys.g.dart';

class InspectorBranchCard extends StatelessWidget {
  final BranchModel branch;
  final VoidCallback? onTap;

  const InspectorBranchCard({super.key, required this.branch, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
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
            const SizedBox(height: 12.0),
            _buildLastInspectionInfo(),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (branch.totalInspections > 0) _buildTotalInspections(),
                if (branch.stop != null) _buildNextInspectionInfo(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Checks if the next inspection is scheduled for today.

  /// Builds the header section with branch name, address, and status badge.
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Text(
                branch.address,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13.0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        if (branch.stop != null) _buildStatusBadge(),
      ],
    );
  }

  /// Builds a badge indicating the branch is in the inspection route.
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pending_actions_rounded,
            size: 14.0,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 5.0),
          Text(
            "In your route",
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the section displaying the last inspection details.
  Widget _buildLastInspectionInfo() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 18.0,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 10.0),
          Text(
            LocaleKeys.last_inspected.tr(),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              textAlign: TextAlign.end,
              branch.lastInspectionDate != null
                  ? "${formatDate(branch.lastInspectionDate!)} (${branch.lastInspectionScore})"
                  : LocaleKeys.pending_first.tr(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the section showing the total number of inspections.
  Widget _buildTotalInspections() {
    return Row(
      children: [
        Icon(
          Icons.fact_check_outlined,
          size: 14.0,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6.0),
        Text(
          '${branch.totalInspections} ${LocaleKeys.total_inspections.tr()}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Builds the section showing the next inspection details.
  Widget _buildNextInspectionInfo() {
    return Row(
      children: [
        Icon(Icons.next_plan, size: 14.0, color: Colors.green),
        const SizedBox(width: 6.0),
        Text(
          branch.isNextInspectionToday
              ? "Today"
              : branch.daysUntilNextInspection == 0
              ? "Tomorrow"
              : "${branch.daysUntilNextInspection} days left",
          style: const TextStyle(fontSize: 12.0, color: Colors.white70),
        ),
      ],
    );
  }
}
