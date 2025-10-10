import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../generated/lib/translations/locale_keys.g.dart';
import '../models/route_model.dart';
class StatusInfo {
  final Color color;
  final IconData icon;
  final String label;
  final bool isToday;
  final bool isOverdue;

  StatusInfo(this.color, this.icon, this.label, this.isToday, this.isOverdue);
}

StatusInfo getStatusInfo(RouteStopModel stop, bool isCompleted) {
  final today = DateTime.now();
  final todayKey = "${today.year}-${today.month}-${today.day}";
  final isToday = stop.timeSlot == todayKey;

  final stopParts = stop.timeSlot.split('-');
  final stopDate = DateTime(
    int.parse(stopParts[0]),
    int.parse(stopParts[1]),
    int.parse(stopParts[2]),
  );
  final isOverdue =
      stopDate.isBefore(DateTime(today.year, today.month, today.day)) &&
      !isCompleted;

  Color color;
  IconData icon;
  String label;

  if (isCompleted) {
    color = Colors.green;
    icon = Icons.check_circle;
    label = LocaleKeys.completed.tr();
  } else if (isOverdue) {
    color = Colors.deepOrange;
    icon = Icons.warning_amber_rounded;
    label = "Overdue";
  } else if (isToday) {
    color = AppColors.primaryRed;
    icon = Icons.hourglass_bottom;
    label = LocaleKeys.waiting.tr();
  } else {
    color = Colors.grey;
    icon = Icons.radio_button_unchecked;
    label = LocaleKeys.pending.tr();
  }

  return StatusInfo(color, icon, label, isToday, isOverdue);
}


String formatTimeSlot(String timeSlot) {
  try {
    final parts = timeSlot.split('-');
    if (parts.length == 3) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final date = DateTime(year, month, day);

      // Format: "Monday, Oct 7"
      return DateFormat('EEEE, MMM d yyyy').format(date);
    }
  } catch (e) {
    // If parsing fails, return original
  }
  return timeSlot;
}
