import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

import '../core/console.dart';
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

List<String> getInspectorTokens(String inspectorId, BuildContext context) {
  try {
    if (inspectorId.isEmpty) {
      console('⚠️ Empty inspectorId provided');
      return [];
    }

    final inspectors = context.read<ProviderAdminUsers>().inspectors;

    if (inspectors.isEmpty) {
      console('⚠️ No inspectors found in provider');
      return [];
    }

    final inspector = inspectors.where((e) => e.id == inspectorId).firstOrNull;

    if (inspector == null) {
      console('⚠️ Inspector $inspectorId not found in provider');
      return [];
    }

    if (inspector.fcmTokens == null || inspector.fcmTokens!.isEmpty) {
      return [];
    }

    return List<String>.from(inspector.fcmTokens!);
  } catch (e) {
    console('⚠️ Error getting inspector tokens for $inspectorId: $e');
    return [];
  }
}

int getMonthFromKey(String monthKey) {
  final parts = monthKey.split('-');
  return parts.length == 2 ? int.parse(parts[0]) : DateTime.now().month;
}

int getYearFromKey(String monthKey) {
  final parts = monthKey.split('-');
  return parts.length == 2 ? int.parse(parts[1]) : DateTime.now().year;
}

String getMonthNameFromKey(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length != 2) return monthKey;
  final month = parts[0];
  var monthNames = {
    "01": LocaleKeys.january.tr(),
    "02": LocaleKeys.february.tr(),
    "03": LocaleKeys.march.tr(),
    "04": LocaleKeys.april.tr(),
    "05": LocaleKeys.may.tr(),
    "06": LocaleKeys.june.tr(),
    "07": LocaleKeys.july.tr(),
    "08": LocaleKeys.august.tr(),
    "09": LocaleKeys.september.tr(),
    "10": LocaleKeys.october.tr(),
    "11": LocaleKeys.november.tr(),
    "12": LocaleKeys.december.tr(),
  };
  return monthNames[month] ?? month;
}

List<String> generateLast12Months() {
  final List<String> months = [];
  final now = DateTime.now();

  for (int i = 0; i < 12; i++) {
    final date = DateTime(now.year, now.month - i, 1);
    final monthKey = '${date.month.toString().padLeft(2, '0')}-${date.year}';
    months.add(monthKey);
  }

  return months;
}


Widget buildNextInspectionInfo({
  required int? daysUntilNextInspection,
  required bool isNextInspectionToday,
  Color textColor = Colors.white70,
}) {
  String text;

  if (isNextInspectionToday) {
    text = LocaleKeys.today.tr();
  } else if (daysUntilNextInspection == 1) {
    text = LocaleKeys.tomorrow.tr();
  } else if (daysUntilNextInspection != null && daysUntilNextInspection < 0) {
    text =
        "${LocaleKeys.daysOverdue.tr().replaceAll("{days}", daysUntilNextInspection.abs().toString())}";
  } else if (daysUntilNextInspection != null) {
    text = "$daysUntilNextInspection ${LocaleKeys.daysLeft.tr()}";
  } else {
    text = "-";
  }

  // Color logic for overdue
  final Color statusColor =
      (daysUntilNextInspection != null && daysUntilNextInspection < 0)
      ? Colors.redAccent
      : Colors.green;

  return Row(
    children: [
      Icon(Icons.next_plan, size: 14.0, color: statusColor),
      const SizedBox(width: 6.0),
      Text(text, style: TextStyle(fontSize: 12.0, color: textColor)),
    ],
  );
}

String? getThumbnailUrl(String videoUrl) {
  try {
    final uri = Uri.parse(videoUrl);
    String? videoId;

    if (uri.host.contains('youtube.com')) {
      videoId = uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      videoId = uri.pathSegments.first;
    }

    if (videoId != null && videoId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
  } catch (e) {
    return null;
  }
  return null;
}
