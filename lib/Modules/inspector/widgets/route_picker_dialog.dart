import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../translations/locale_keys.g.dart';

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

  // FIX: Ensure selectedDate is not before today
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime selectedDate = dateToUse.isBefore(today) ? today : dateToUse;

  return await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocaleKeys.select_date.tr(),
          style: const TextStyle(
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
              style: const TextStyle(color: Colors.grey, fontSize: 16),
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
              style: const TextStyle(
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
