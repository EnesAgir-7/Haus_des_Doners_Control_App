import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/route_model.dart';
import '../translations/locale_keys.g.dart';

class StopStatus {
  final String text;
  final Color color;
  final IconData icon;

  const StopStatus({
    required this.text,
    required this.color,
    required this.icon,
  });
}

class StatisticCard extends StatelessWidget {
  final RouteStopModel stop;

  const StatisticCard({super.key, required this.stop});

  StopStatus getStatus() {
    if (stop.isCompleted) {
      return StopStatus(
        text: LocaleKeys.completed.tr(),
        color: Colors.green,
        icon: Icons.check_box,
      );
    } else {
      return StopStatus(
        text: LocaleKeys.waiting.tr(),
        color: Colors.amber,
        icon: Icons.hourglass_bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = getStatus();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with colored accent bar
          Container(
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(left: BorderSide(width: 4, color: status.color)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Time Slot
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 20,
                      color: status.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stop.timeSlot.toString(),
                      style: TextStyle(
                        color: status.color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: status.color.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 16, color: status.color),
                      const SizedBox(width: 6),
                      Text(
                        status.text,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch Name
                Text(
                  stop.branchName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 16),

                // Info Row - Assigned Date
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.event_rounded,
                          size: 18,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocaleKeys.assigned_at.tr(),
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat(
                                'dd MMM yyyy, HH:mm',
                              ).format(stop.createdAt ?? DateTime.now()),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Score Section (if completed)
                if (stop.isCompleted) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.score.tr(),
                                style: TextStyle(
                                  color: AppColors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stop.inspectionId != null ? '9.0' : '-',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// class StatisticCard extends StatelessWidget {
//   final String time;
//   final String title;
//   final String status;
//   final String subtitle;
//   final Color statusColor;
//   final IconData icon;

//   const StatisticCard({
//     super.key,
//     required this.time,
//     required this.title,
//     required this.status,
//     required this.statusColor,
//     required this.subtitle,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.lightBlack,
//         borderRadius: BorderRadius.circular(12),
//         border: Border(left: BorderSide(width: 3, color: AppColors.primaryRed)),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             time,
//             style: const TextStyle(
//               color: AppColors.primaryRed,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Text(
//             title,
//             style: const TextStyle(
//               color: AppColors.white,
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Row(
//             children: [
//               Icon(icon, size: 16, color: statusColor),
//               const SizedBox(width: 4),
//               Text(status, style: TextStyle(color: statusColor, fontSize: 13)),
//               if (subtitle.isNotEmpty) ...[
//                 const SizedBox(width: 6),
//                 Text(
//                   "($subtitle)",
//                   style: const TextStyle(
//                     color: AppColors.lightGrey,
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
