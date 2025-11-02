import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/route_model.dart';
import '../../../translations/locale_keys.g.dart';

class StatusInfo {
  final Color color;
  final IconData icon;
  final String label;
  final bool isToday;
  final bool isOverdue;
  final bool isExpired;

  StatusInfo(
    this.color,
    this.icon,
    this.label,
    this.isToday,
    this.isOverdue,
    this.isExpired,
  );
}

StatusInfo getStatusInfo(RouteStopModel stop, bool isCompleted) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  DateTime? stopDate;

  // Safely parse stop.timeSlot (expected format: yyyy-MM-dd)
  try {
    final parts = stop.timeSlot.split('-');
    if (parts.length == 3) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      stopDate = DateTime(year, month, day);
    }
  } catch (_) {
    stopDate = null;
  }

  if (stopDate == null) {
    // fallback if invalid
    return StatusInfo(
      Colors.grey,
      Icons.error_outline,
      'Invalid date',
      false,
      false,
      false,
    );
  }

  final todayKey =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
  final isToday = stop.timeSlot == todayKey;

  final bool isExpired =
      stop.isCompleted &&
      stop.completedAt != null &&
      stop.completedAt!.isBefore(todayDate);

  final bool isOverdue = stopDate.isBefore(todayDate) && !isCompleted;

  Color color;
  IconData icon;
  String label;

  if (isExpired) {
    color = Colors.deepOrange;
    icon = Icons.warning_amber_rounded;
    label = LocaleKeys.expired.tr();
  } else if (isCompleted) {
    color = Colors.green;
    icon = Icons.check_circle;
    label = LocaleKeys.completed.tr();
  } else if (isOverdue) {
    color = Colors.deepOrange;
    icon = Icons.warning_amber_rounded;
    label = LocaleKeys.overdue.tr();
  } else if (isToday) {
    color = AppColors.primaryRed;
    icon = Icons.hourglass_bottom;
    label = LocaleKeys.waiting.tr();
  } else {
    color = Colors.grey;
    icon = Icons.radio_button_unchecked;
    label = LocaleKeys.pending.tr();
  }

  return StatusInfo(color, icon, label, isToday, isOverdue, isExpired);
}

String formatTimeSlot(String timeSlot) {
  try {
    final parts = timeSlot.split('-');
    if (parts.length == 3) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final date = DateTime(year, month, day);
      return DateFormat(
        'EEEE, MMM d yyyy',
      ).format(date); // e.g. "Thursday, Oct 2 2025"
    }
  } catch (_) {}
  return timeSlot;
}
