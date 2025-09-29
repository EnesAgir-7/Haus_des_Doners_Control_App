import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class StatisticCard extends StatelessWidget {
  final String time;
  final String title;
  final String status;
  final String subtitle;
  final Color statusColor;
  final IconData icon;

  const StatisticCard({
    super.key,
    required this.time,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(width: 3, color: AppColors.primaryRed)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(color: statusColor, fontSize: 13)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  "($subtitle)",
                  style: const TextStyle(
                    color: AppColors.lightGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
