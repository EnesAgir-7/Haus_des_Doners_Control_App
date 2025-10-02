import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageHelper {
  LocalStorageHelper._privateConstructor();

  static final LocalStorageHelper instance =
      LocalStorageHelper._privateConstructor();

  /// Save any object as JSON string
  Future<void> saveData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(value);
    await prefs.setString(key, jsonString);
  }

  /// Load any object from JSON string
  Future<Map<String, dynamic>?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return map;
    } catch (e) {
      print("⚠️ Failed to decode JSON from SharedPreferences: $e");
      return null;
    }
  }

  /// Delete a key from SharedPreferences
  Future<void> removeData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
}
