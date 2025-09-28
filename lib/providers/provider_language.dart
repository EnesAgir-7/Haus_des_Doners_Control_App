import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderLanguage with ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  ProviderLanguage() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('localeCode');
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('localeCode', locale.languageCode);
  }

  Future<void> clearLocale() async {
    _locale = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('localeCode');
  }
}
