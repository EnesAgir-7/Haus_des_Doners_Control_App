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
