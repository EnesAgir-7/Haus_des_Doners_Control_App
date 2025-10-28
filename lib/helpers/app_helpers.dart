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
