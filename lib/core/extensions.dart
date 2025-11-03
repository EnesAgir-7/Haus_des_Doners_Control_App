import 'package:easy_localization/easy_localization.dart';

import '../translations/locale_keys.g.dart';

extension DateTimeExtension on DateTime {
  String getFormattedDateTime() {
    return DateFormat(
      'dd MMM yyyy, hh:mm a',
      'en_US',
    ).format(this.toLocal()).replaceAll('AM/PM', '');
  }
}

extension StringCamelCase on String {
  /// Converts a string like "Hello What" to "helloWhat"
  String toCamelCase() {
    if (isEmpty) return '';

    // Split by spaces
    final words = split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';

    final firstWord = words.first.toLowerCase();
    final restWords = words.skip(1).map((word) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();

    return '$firstWord$restWords';
  }
}

extension StringCapitalizedWords on String {
  /// Capitalizes the first letter of each word and keeps spaces
  String capitalizeWords() {
    if (isEmpty) return '';
    return split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

extension KeywordExtension on String {
  /// Returns the corresponding LocaleKey from translations
  String toLocaleKey() {
    switch (this) {
      case 'all':
        return LocaleKeys.all.tr();
      case 'pending':
        return LocaleKeys.pending.tr();
      case 'completed':
        return LocaleKeys.completed.tr();
      case 'in_progress':
        return LocaleKeys.inProgress.tr();
      case 'overdue':
        return LocaleKeys.overdue.tr();
      default:
        throw Exception('Unknown keyword: $this');
    }
  }
}
