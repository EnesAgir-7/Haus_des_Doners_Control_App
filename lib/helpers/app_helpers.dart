import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy, hh:mm a').format(date);
}
Color getScoreColor(String scoreString) {
  if (!scoreString.contains('/')) return Colors.grey;

  try {
    // Use your global percentage calculation method
    final percentage = calculatePerformancePercent(scoreString);
    final percentValue = double.tryParse(percentage) ?? 0.0;

    // Use your global color method for consistency
    return getPercentageColor(percentValue);
  } catch (e) {
    print('Error in getScoreColor: $e');
    return Colors.grey;
  }
}

Color getPercentageColor(double percentage) {
  if (percentage == 100) {
    return Colors.green;
  } else if (percentage == 75) {
    return AppColors.amber;
  } else if (percentage == 25) {
    return Colors.deepOrange;
  } else {
    return AppColors.primaryRed;
  }
}

IconData getPercentageIcon(double percentage) {
  if (percentage == 100) {
    return Icons.emoji_events; // Excellent
  } else if (percentage == 75) {
    return Icons.thumb_up; // Good
  } else if (percentage == 25) {
    return Icons.warning; // Fair
  } else {
    return Icons.error; // Poor / 0%
  }
}

String calculatePerformancePercent(String totalScoreStr) {
  final parts = totalScoreStr.split('/');
  if (parts.length != 2) return '100';

  final points = double.tryParse(parts[0]) ?? 0.0;
  final maxPoints = double.tryParse(parts[1]) ?? 1.0;

  if (maxPoints <= 0) return '100';

  final avgScorePerQuestion = points / maxPoints * 4; // scale to 1–4

  // Map average score to your custom percentage
  double percentage;
  if (avgScorePerQuestion <= 1) {
    percentage = 100;
  } else if (avgScorePerQuestion <= 2) {
    percentage = 75;
  } else if (avgScorePerQuestion <= 3) {
    percentage = 25;
  } else {
    percentage = 0;
  }

  return '${percentage.toStringAsFixed(0)}';
}

Future<String?> pickRouteDate(
  BuildContext context, {
  String? currentTimeSlot,
  DateTime? initialDate,
  int maxDaysAhead = 7,
}) async {
  // Parse the current time slot if provided
  DateTime? parsedInitialDate;

  if (currentTimeSlot != null && currentTimeSlot.isNotEmpty) {
    try {
      // Handle both formats: "2025-11-2" and "2025-11-02"
      final parts = currentTimeSlot.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        parsedInitialDate = DateTime(year, month, day);
      }
    } catch (_) {
      parsedInitialDate = null;
    }
  }

  // Determine which date to use as initial
  final dateToUse = parsedInitialDate ?? initialDate ?? DateTime.now();
  DateTime selectedDate = dateToUse;

  return await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocaleKeys.select_date.tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 400,
              height: 400,
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: maxDaysAhead)),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              final formattedDate = DateFormat(
                'yyyy-MM-dd',
              ).format(selectedDate);
              Navigator.pop(context, formattedDate);
            },
            child: Text(
              LocaleKeys.ok.tr(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    },
  );
}


List<String> getInspectorTokens(String inspectorId, BuildContext context) {
  final inspector =  context.read<ProviderAdminUsers>().inspectors.firstWhere(
    (e) => e.id == inspectorId,
    // orElse: () => null,
  );
  if (inspector.fcmTokens == null) return [];
  return List<String>.from(inspector.fcmTokens!);
}
