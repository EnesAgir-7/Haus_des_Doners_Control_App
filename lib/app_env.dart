import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/core/console.dart';
import 'firebase_options_dev.dart' as dev_firebase;
import 'firebase_options_prod.dart' as prod_firebase;

class AppEnvironment {
  // ⚠️ CHANGE THIS FLAG TO SWITCH ENVIRONMENTS ⚠️
  static const bool isProduction =
      true; // 👈 CHANGE THIS: true = prod, false = dev

  // Environment types
  static const String dev = 'dev';
  static const String prod = 'prod';

  // Current environment based on flag
  static String get current => isProduction ? prod : dev;

  // Easy boolean checks
  static bool get isDev => !isProduction;
  static bool get isProd => isProduction;

  // Config cache
  static Map<String, dynamic>? _config;

  // Get Firebase options based on environment
  static FirebaseOptions get firebaseOptions {
    return isProd
        ? prod_firebase.DefaultFirebaseOptions.currentPlatform
        : dev_firebase.DefaultFirebaseOptions.currentPlatform;
  }

  // Get app name from config (with fallback)
  static String get appName =>
      getConfig('appName') ??
      (isProd ? 'Haus des Döners' : 'Haus des Döners Dev');

  // Load config from JSON file
  static Future<void> loadConfig() async {
    try {
      final configPath = isProd
          ? 'assets/config/prod.json'
          : 'assets/config/dev.json';
      final configString = await rootBundle.loadString(configPath);
      _config = json.decode(configString) as Map<String, dynamic>;
      console('✅ Loaded config from: $configPath', type: DebugType.alert);
    } catch (e) {
      console('❌ Error loading config: $e', type: DebugType.error);
    }
  }

  // Get config value by key
  static String? getConfig(String key) {
    return _config?[key]?.toString();
  }

  // Get all config
  static Map<String, dynamic>? get config => _config;

  // Print current environment
  static void printEnvironment() {
    console(
      '🚀 App is Running in: ${current.toUpperCase()} MODE',
      type: DebugType.alert,
    );
  }
}
