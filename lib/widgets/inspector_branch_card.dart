import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/helpers/app_helpers.dart';

import '../core/constants/app_colors.dart';
import '../models/branch_model.dart';
import '../translations/locale_keys.g.dart';

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
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildLastInspectionInfo(),
            if (branch.totalInspections > 0) ...[
              const SizedBox(height: 12),
              _buildTotalInspections(),
            ],
          ],
        ),
      ),
    );
  }

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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                branch.address,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusBadge(branch.isRouteAssigned),
      ],
    );
  }

  Widget _buildStatusBadge(bool isAssigned) {
    if (!isAssigned) return SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pending_actions_rounded,
            size: 14,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 5),
          Text(
            LocaleKeys.in_queue.tr(),
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastInspectionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          Text(
            LocaleKeys.last_inspected.tr(),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            branch.lastInspectionDate != null
                ? "${formatDate(branch.lastInspectionDate!)} (${branch.lastInspectionScore})"
                : LocaleKeys.pending_first.tr(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalInspections() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.fact_check_outlined, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '${branch.totalInspections} ${LocaleKeys.total_inspections.tr()}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
