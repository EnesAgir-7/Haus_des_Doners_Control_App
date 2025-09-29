import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../translations/locale_keys.g.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  static const Map<String, Map<String, String>> _languages = {
    'en': {'name': 'English', 'flag': '🇬🇧'},
    'tr': {'name': 'Türkçe', 'flag': '🇹🇷'},
    'de': {'name': 'German', 'flag': '🇩🇪'},
  };

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language, color: Colors.white),
      tooltip: LocaleKeys.change_language.tr(),
      onPressed: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocaleKeys.select_language.tr()),
          content: SingleChildScrollView(
            child: ListBody(
              children: _languages.entries.map((entry) {
                return ListTile(
                  leading: Text(
                    entry.value['flag']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(entry.value['name']!),
                  onTap: () {
                    context.setLocale(Locale(entry.key));
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocaleKeys.cancel.tr()),
            ),
          ],
        );
      },
    );
  }
}
