import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firebase_constants.dart';
import '../../generated/lib/translations/locale_keys.g.dart';
import '../../models/route_model.dart';
import '../common_methods.dart';
import '../user/control_page.dart';

void showStopInfoBottomSheet(RouteStopModel stop, BuildContext context) {
  final isCompleted = stop.status == AppConstants.completed;
  final statusInfo = getStatusInfo(stop, isCompleted);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.primaryDark,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with gradient
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: statusInfo.isOverdue
                    ? [AppColors.primaryRed, AppColors.primaryDark]
                    : statusInfo.isToday
                    ? [Color(0xFF4CAF50), Color(0xFF2E7D32)]
                    : [AppColors.primaryRed, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: statusInfo.color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.store, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.branchName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusInfo.icon,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  statusInfo.label,
                                  style: TextStyle(
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
                  ],
                ),
              ],
            ),
          ),

          // Information Cards
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Scheduled Date
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  iconColor: AppColors.primaryRed,
                  title: "Schedule Date",
                  value: formatTimeSlot(stop.timeSlot),
                ),
                SizedBox(height: 12),

                // Order Position
                _buildInfoCard(
                  icon: Icons.format_list_numbered,
                  iconColor: Colors.orange,
                  title: "Stop Order",
                  value: "#${stop.order}",
                ),

                if (isCompleted && stop.completedAt != null) ...[
                  SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                    title: "Completed At",
                    value: DateFormat(
                      "MMMM d, yyyy 'at' h:mm a",
                    ).format(stop.completedAt!),
                  ),
                ],

                SizedBox(height: 16),

                // Action Buttons - Only for today or overdue stops that are not completed
                if ((statusInfo.isToday || statusInfo.isOverdue) &&
                    !isCompleted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ControlPage(
                              branchId: stop.branchId,
                              branchTemplateId: stop.branchTemplateId,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.arrow_forward),
                      label: Text(
                        statusInfo.isOverdue
                            ? "Inspect Now"
                            : LocaleKeys.start_inspection.tr(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusInfo.isOverdue
                            ? Colors.deepOrange
                            : AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildInfoCard({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String value,
}) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          iconColor.withValues(alpha: 0.1),
          iconColor.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: iconColor.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
