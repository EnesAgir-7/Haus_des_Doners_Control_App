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
    } else if (stop.isCurrent) {
      return StopStatus(
        text: LocaleKeys.current_location.tr(),
        color: Colors.blue,
        icon: Icons.my_location,
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
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(width: 3, color: status.color)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stop.timeSlot.split(' - ')[0],
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stop.branchName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(status.icon, size: 16, color: status.color),
              const SizedBox(width: 4),
              Text(
                status.text,
                style: TextStyle(color: status.color, fontSize: 13),
              ),

              const SizedBox(width: 6),
              Text(
                stop.isCompleted
                    ? "${LocaleKeys.score.tr()}: ${stop.inspectionId != null ? '9.0' : '-'}"
                    : "",
                style: const TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 13,
                ),
              ),
            ],
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
