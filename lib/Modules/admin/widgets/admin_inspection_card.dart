import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/helpers/app_helpers.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/inspection_model.dart';
import '../../../translations/locale_keys.g.dart';

class AdminInspectionCard extends StatelessWidget {
  final InspectionModel inspection;
  final VoidCallback? onTap;

  const AdminInspectionCard({super.key, required this.inspection, this.onTap});

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
            _buildBranchInfo(),
            const SizedBox(height: 8.0),
            _buildInspectorInfo(),
            const SizedBox(height: 8.0),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildScore() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (inspection.status == AppConstants.completed) _buildScoreBadge(),
      ],
    );
  }

  Widget _buildScoreBadge() {
    final scoreColor = getScoreColor(inspection.score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: scoreColor, width: 0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14.0, color: scoreColor),
          const SizedBox(width: 5.0),
          Text(
            inspection.score,
            style: TextStyle(
              color: scoreColor,
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchInfo() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.apartment,
            size: 20.0,
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        inspection.branchName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    _buildScore(),
                  ],
                ),
                if (inspection.overallNotes.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    inspection.overallNotes,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorInfo() {
    return Row(
      children: [
        Icon(Icons.person, size: 16.0, color: Colors.grey.shade500),
        const SizedBox(width: 6.0),
        Text(
          "${LocaleKeys.inspector.tr()} - ${inspection.inspectorName}",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDateInfo(),
        if (inspection.categories.isNotEmpty) _buildCategoriesCount(),
      ],
    );
  }

  Widget _buildDateInfo() {
    final date =
        inspection.status == AppConstants.completed &&
            inspection.completedTime != null
        ? inspection.completedTime!
        : DateTime.tryParse(inspection.scheduledTime) ?? inspection.createdAt;

    final prefix = inspection.status == AppConstants.completed
        ? "${LocaleKeys.completed.tr()}: "
        : inspection.status == AppConstants.scheduled
        ? LocaleKeys.scheduled.tr()
        : LocaleKeys.created.tr();

    return Row(
      children: [
        Icon(
          inspection.status == AppConstants.completed
              ? Icons.check_circle_outline
              : Icons.calendar_today_outlined,
          size: 14.0,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6.0),
        Text(
          "$prefix${formatDate(date)}",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesCount() {
    return Row(
      children: [
        Icon(Icons.category_outlined, size: 14.0, color: Colors.grey.shade600),
        const SizedBox(width: 6.0),
        Text(
          "${inspection.categories.length} ${LocaleKeys.categories.tr()}",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
