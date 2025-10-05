import 'package:easy_localization/easy_localization.dart';

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy, hh:mm a').format(date);
}
