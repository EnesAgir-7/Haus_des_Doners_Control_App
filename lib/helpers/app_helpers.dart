import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy, hh:mm a').format(date);
}

Future<void> openInBrowser(String pdfUrl, BuildContext context) async {
  final uri = Uri.parse(pdfUrl);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
  // if (await canLaunchUrl(uri)) {
  //   console("Yes it can ba lauch");
  // } else {
  //   console("it cannot be laucnhed");
  //   showSnakBarr(context, "Could not open the report link.");
  // }
}

Color getScoreColor(String scoreString) {
  if (!scoreString.contains('/')) return Colors.grey;

  final parts = scoreString.split('/');
  final obtained = double.tryParse(parts[0].trim()) ?? 0;
  final total = double.tryParse(parts[1].trim()) ?? 1;

  // Prevent division by zero
  if (total == 0) return Colors.grey;

  // Calculate ratio (0.0 = perfect, 1.0 = worst)
  final ratio = obtained / total;

  // Determine color — lower ratio = greener
  if (ratio <= 0.3) return Colors.green;
  if (ratio <= 0.6) return Colors.amber;
  return Colors.red;
}

// String calculatePerformancePercent(averageScoreStr) {
//   final parts = averageScoreStr.split('/');
//   double percentage = 0.0;
//   if (parts.length == 2) {
//     final points = double.tryParse(parts[0]) ?? 0.0;
//     final total = double.tryParse(parts[1]) ?? 1.0;

//     if (total > 0) {
//       percentage = (points / total) * 100.0;
//     } else {
//       percentage = 0.0; // Avoid division by zero
//     }
//   } else {
//     percentage = double.tryParse(averageScoreStr) ?? 0.0;
//   }

//   return '${percentage.toStringAsFixed(0)}';
// }

String calculatePerformancePercent(String totalScoreStr) {
  // totalScoreStr example: "17/24" -> points / maxPoints
  final parts = totalScoreStr.split('/');
  if (parts.length != 2) return '100';

  final points = double.tryParse(parts[0]) ?? 0.0;
  final maxPoints = double.tryParse(parts[1]) ?? 1.0;

  if (maxPoints <= 0) return '100';

  // Calculate average score per question
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
      // Fallback to now if parsing fails
      parsedInitialDate = null;
    }
  }

  // Use priority: currentTimeSlot > initialDate > now
  final dateToUse = parsedInitialDate ?? initialDate ?? DateTime.now();

  // Show date picker
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: dateToUse,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(Duration(days: maxDaysAhead)),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: Theme.of(context).primaryColor,
            onPrimary: Colors.white,
            surface: const Color(0xFF212121),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      );
    },
  );

  if (pickedDate == null) return null;

  // ✅ Return formatted date string
  return DateFormat('yyyy-MM-dd').format(pickedDate);
}
