import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_branches.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/lib/translations/locale_keys.g.dart';
import '../../../models/route_model.dart';
import '../widgets/app_button.dart';
import '../screens/screen_submit_report.dart';
// void showStopInfoBottomSheet(RouteStopModel stop, BuildContext context) {
//   final isCompleted = stop.status == AppConstants.completed;
//   final statusInfo = getStatusInfo(stop, isCompleted);

//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: AppColors.primaryDark,
//     builder: (context) => Container(
//       decoration: BoxDecoration(
//         color: AppColors.primaryDark,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(24),
//           topRight: Radius.circular(24),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Handle bar
//           Container(
//             margin: EdgeInsets.only(top: 12),
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),

//           // Header with gradient
//           Container(
//             width: double.infinity,
//             margin: EdgeInsets.all(16),
//             padding: EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: statusInfo.isOverdue
//                     ? [AppColors.primaryRed, AppColors.primaryDark]
//                     : statusInfo.isToday
//                     ? [Color(0xFF4CAF50), Color(0xFF2E7D32)]
//                     : [AppColors.primaryRed, AppColors.primaryDark],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: statusInfo.color.withValues(alpha: 0.3),
//                   blurRadius: 12,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withValues(alpha: 0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Icon(Icons.store, color: Colors.white, size: 28),
//                     ),
//                     SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             stop.branchName,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withValues(alpha: 0.25),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   statusInfo.icon,
//                                   size: 14,
//                                   color: Colors.white,
//                                 ),
//                                 SizedBox(width: 6),
//                                 Text(
//                                   statusInfo.label,
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Information Cards
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: Column(
//               children: [
//                 // Scheduled Date
//                 _buildInfoCard(
//                   icon: Icons.calendar_today,
//                   iconColor: AppColors.primaryRed,
//                   title: "Schedule Date",
//                   value: formatTimeSlot(stop.timeSlot),
//                 ),
//                 SizedBox(height: 12),

//                 // Order Position
//                 _buildInfoCard(
//                   icon: Icons.format_list_numbered,
//                   iconColor: Colors.orange,
//                   title: "Stop Order",
//                   value: "#${stop.order}",
//                 ),

//                 if (isCompleted && stop.completedAt != null) ...[
//                   SizedBox(height: 12),
//                   _buildInfoCard(
//                     icon: Icons.check_circle,
//                     iconColor: Colors.green,
//                     title: "Completed At",
//                     value: DateFormat(
//                       "MMMM d, yyyy 'at' h:mm a",
//                     ).format(stop.completedAt!),
//                   ),
//                 ],

//                 SizedBox(height: 16),

//                 // Action Buttons - Only for today or overdue stops that are not completed
//                 if ((statusInfo.isToday || statusInfo.isOverdue) &&
//                     !isCompleted) ...[
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => ControlPage(
//                               branchId: stop.branchId,
//                               branchTemplateId: stop.branchTemplateId,
//                             ),
//                           ),
//                         );
//                       },
//                       icon: Icon(Icons.arrow_forward),
//                       label: Text(
//                         statusInfo.isOverdue
//                             ? "Inspect Now"
//                             : LocaleKeys.start_inspection.tr(),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: statusInfo.isOverdue
//                             ? Colors.deepOrange
//                             : AppColors.primaryRed,
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                 ],

//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text(
//                     "Close",
//                     style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// Widget _buildInfoCard({
//   required IconData icon,
//   required Color iconColor,
//   required String title,
//   required String value,
// }) {
//   return Container(
//     padding: EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       gradient: LinearGradient(
//         colors: [
//           iconColor.withValues(alpha: 0.1),
//           iconColor.withValues(alpha: 0.05),
//         ],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: iconColor.withValues(alpha: 0.2)),
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: iconColor.withValues(alpha: 0.15),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(icon, color: iconColor, size: 22),
//         ),
//         SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               SizedBox(height: 4),
//               Text(
//                 value,
//                 style: TextStyle(
//                   color: AppColors.white,
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }

void showStopInfoBottomSheet(RouteStopModel stop, BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.primaryDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => CompactStopInfoSheet(stop: stop),
  );
}

class CompactStopInfoSheet extends StatelessWidget {
  final RouteStopModel stop;

  const CompactStopInfoSheet({super.key, required this.stop});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStopStatusInfo();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            _buildHeaderAndInfo(context, statusInfo),
            _buildActionButtons(context, statusInfo),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeaderAndInfo(BuildContext context, _StopStatusInfo statusInfo) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: statusInfo.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusInfo.color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.branchName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusInfo.icon, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            statusInfo.label,
                            style: const TextStyle(
                              color: Colors.white,
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
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactInfoItem(
                icon: Icons.calendar_today,
                label: "Scheduled Date",
                value: formatTimeSlot(stop.timeSlot),
              ),
              if ((stop.isCompleted || stop.isExpired) &&
                  stop.completedAt != null)
                _buildCompactInfoItem(
                  icon: Icons.check_circle,
                  label: "Completed At",
                  value: DateFormat(
                    "MMMM d, yyyy 'at' h:mm a",
                  ).format(stop.completedAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- FULLY CORRECTED BUTTON AND STATUS LOGIC ---
  Widget _buildActionButtons(BuildContext context, _StopStatusInfo statusInfo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), // Added top padding
      child: Column(
        children: [
          // Case 1: Stop is completed OR expired (show info banner)
          if (stop.isCompleted || stop.isExpired)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusInfo.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusInfo.icon, color: statusInfo.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.isExpired
                              ? "Route Expired"
                              : "Inspection Completed",
                          style: TextStyle(
                            color: statusInfo.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          stop.isExpired
                              ? "This route is expired. You can remove it from your routes."
                              : stop.isCompleted
                              ? "This inspection is already completed. You can remove it from your routes."
                              : "Inspection Completed",
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: statusInfo.color),
                    onPressed: () => _showRouteManagementSheet(context),
                  ),
                ],
              ),
            ),

          // Case 2: Stop is actionable (Today or Overdue, but NOT completed)
          if (!stop.isCompleted && (statusInfo.isToday || statusInfo.isOverdue))
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScreenSubmitReport(
                            branchId: stop.branchId,
                            branchTemplateId: stop.branchTemplateId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: Text(_getActionButtonText(statusInfo)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getActionButtonColor(statusInfo),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _showRouteManagementSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Icon(Icons.edit, size: 20),
                ),
              ],
            ),

          // Case 3: Stop is in the future (and not completed)
          if (!stop.isCompleted && !statusInfo.isToday && !statusInfo.isOverdue)
            AppButton(
              text: "Edit Route",
              onPressed: () => _showRouteManagementSheet(context),
              backgroundColor: AppColors.primaryRed,
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              borderRadius: 12,
            ),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  String formatTimeSlot(String timeSlot) {
    try {
      final date = _parseTimeSlot(timeSlot);
      return date != null ? DateFormat("MMMM d, yyyy").format(date) : timeSlot;
    } catch (e) {
      return timeSlot;
    }
  }

  void _showRouteManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StopRouteManagementSheet(stop: stop),
    );
  }

  String _getActionButtonText(_StopStatusInfo statusInfo) {
    if (statusInfo.isOverdue) return "Inspect Now";
    if (stop.isCurrent) return "Continue";
    return LocaleKeys.start_inspection.tr();
  }

  Color _getActionButtonColor(_StopStatusInfo statusInfo) {
    if (statusInfo.isOverdue) return Colors.red.shade700;
    if (stop.isCurrent) return Colors.amber.shade700;
    return AppColors.primaryRed;
  }

  _StopStatusInfo _getStopStatusInfo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDate = _parseTimeSlot(stop.timeSlot);

    // Corrected Logic: Check for Expired BEFORE Completed, as an expired stop is a subset of completed.
    if (stop.isExpired) {
      return _StopStatusInfo(
        label: "Expired",
        icon: Icons.warning_amber_rounded,
        color: Colors.deepOrange,
        gradientColors: [Colors.deepOrange, Colors.red],
      );
    }
    if (stop.isCompleted) {
      return _StopStatusInfo(
        label: "Completed",
        icon: Icons.check_circle,
        color: Colors.green,
        gradientColors: [Colors.green, const Color(0xFF2E7D32)],
      );
    }

    final isToday =
        scheduledDate != null && scheduledDate.isAtSameMomentAs(today);
    final isOverdue = scheduledDate != null && scheduledDate.isBefore(today);

    if (isOverdue) {
      return _StopStatusInfo(
        label: "Overdue",
        icon: Icons.error_outline,
        color: Colors.red,
        gradientColors: [Colors.red.shade700, Colors.red.shade900],
        isOverdue: true,
      );
    }
    if (isToday) {
      if (stop.isCurrent) {
        return _StopStatusInfo(
          label: "In Progress",
          icon: Icons.play_circle_outline,
          color: Colors.amber,
          gradientColors: [Colors.amber, Colors.orange],
          isToday: true,
        );
      }
      return _StopStatusInfo(
        label: "Today",
        icon: Icons.today,
        color: Colors.green,
        gradientColors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
        isToday: true,
      );
    }
    return _StopStatusInfo(
      label: "Scheduled",
      icon: Icons.schedule,
      color: Colors.blue,
      gradientColors: [AppColors.primaryRed, AppColors.primaryDark],
    );
  }

  DateTime? _parseTimeSlot(String timeSlot) {
    try {
      return DateTime.parse(timeSlot);
    } catch (e) {
      return null;
    }
  }
}

// Helper class to hold status info
class _StopStatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final bool isToday;
  final bool isOverdue;

  _StopStatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.gradientColors,
    this.isToday = false,
    this.isOverdue = false,
  });
}

// Stop Route Management Bottom Sheet
class StopRouteManagementSheet extends StatelessWidget {
  final RouteStopModel stop;

  const StopRouteManagementSheet({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),
          Icon(Icons.route, size: 48, color: AppColors.primaryRed),
          SizedBox(height: 16),
          Text(
            "Manage Stop",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            stop.branchName,
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),

          Consumer<ProviderBranches>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  if (!stop.isCompleted)
                    AppButton(
                      isLoading: provider.isLoading,
                      text: "Update Schedule",
                      onPressed: () async {
                        // Parse existing timeSlot (e.g. "2025-10-23") to DateTime
                        DateTime? initialDate;
                        try {
                          if (stop.timeSlot.isNotEmpty) {
                            initialDate = DateTime.parse(stop.timeSlot);
                          }
                        } catch (_) {
                          initialDate = DateTime.now();
                        }

                        final DateTime? pickedDate = await showDatePicker(
                          locale: context.locale,
                          context: context,
                          initialDate: initialDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                        );

                        if (pickedDate != null) {
                          final String newTimeSlot =
                              "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";

                          // Call your provider method to update the stop schedule
                          final success = await provider
                              .updateStopTimeSlotForMe(
                                branchId: stop.branchId,
                                context: context,
                                newTimeSlot: newTimeSlot,
                                order: stop.order,
                              );

                          if (success && context.mounted) {
                            Navigator.pop(
                              context,
                            ); // Close route management sheet
                            Navigator.pop(context); // Close stop details sheet
                          }
                        }
                      },
                      backgroundColor: AppColors.amber,
                      textStyle: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      borderRadius: 10,
                    ),
                  SizedBox(height: 12),
                  AppButton(
                    isLoading: provider.isLoading,
                    text: "Remove from Route",
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.lightBlack,
                          title: Text(
                            "Remove Stop",
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            "Are you sure you want to remove ${stop.branchName} from your route?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                "Remove",
                                style: TextStyle(color: AppColors.primaryRed),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        // Call your provider method to remove the stop
                        final success = await provider.unAssignMyRoute(
                          branchId: stop.branchId,
                          context: context,
                        );

                        if (success && context.mounted) {
                          Navigator.pop(
                            context,
                          ); // Close route management sheet
                          Navigator.pop(context); // Close stop details sheet
                        }
                      }
                    },
                    backgroundColor: AppColors.primaryRed,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: 10,
                  ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
