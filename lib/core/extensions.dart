import 'package:easy_localization/easy_localization.dart';

extension DateTimeExtension on DateTime {
  String getFormattedDateTime() {
    return DateFormat(
      'dd MMM yyyy, HH:mm a',
    ).format(DateTime.parse(this.toIso8601String().replaceAll('Z', '+00:00')));
  }
}
