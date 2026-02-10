import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized service for Firebase Crashlytics crash reporting and error logging
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize Crashlytics (call this in main.dart after Firebase.initializeApp)
  static void initialize() {
    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint('✅ Crashlytics initialized');
  }

  /// Log a non-fatal error with context
  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) async {
    try {
      // Add context as custom keys
      if (context != null) {
        for (var entry in context.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      debugPrint(
        '📊 Error logged to Crashlytics: ${reason ?? exception.toString()}',
      );
    } catch (e) {
      debugPrint('⚠️ Failed to log error to Crashlytics: $e');
    }
  }

  /// Log a message/event for debugging
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
      debugPrint('📝 Crashlytics log: $message');
    } catch (e) {
      debugPrint('⚠️ Failed to log message to Crashlytics: $e');
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      debugPrint('👤 Crashlytics user ID set: $userId');
    } catch (e) {
      debugPrint('⚠️ Failed to set user ID in Crashlytics: $e');
    }
  }

  /// Set custom key-value pairs for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value.toString());
    } catch (e) {
      debugPrint('⚠️ Failed to set custom key in Crashlytics: $e');
    }
  }

  /// Set multiple custom keys at once
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    try {
      for (var entry in keys.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    } catch (e) {
      debugPrint('⚠️ Failed to set custom keys in Crashlytics: $e');
    }
  }

  /// Force a crash for testing (DEBUG ONLY - never call in production!)
  void testCrash() {
    if (kDebugMode) {
      debugPrint('🧪 Forcing test crash...');
      _crashlytics.crash();
    } else {
      debugPrint('⚠️ Test crash only available in debug mode');
    }
  }

  /// Clear user identification
  Future<void> clearUser() async {
    try {
      await _crashlytics.setUserIdentifier('');
      debugPrint('👤 Crashlytics user ID cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear user ID in Crashlytics: $e');
    }
  }

  /// Log inspection submission stage for debugging
  Future<void> logInspectionStage(
    String stage, {
    Map<String, dynamic>? data,
  }) async {
    await log('Inspection Stage: $stage');
    if (data != null) {
      await setCustomKeys(data);
    }
  }

  /// Check if Crashlytics is enabled
  bool get isCrashlyticsCollectionEnabled {
    return _crashlytics.isCrashlyticsCollectionEnabled;
  }

  /// Enable/disable Crashlytics collection
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
      debugPrint(
        '${enabled ? "✅ Enabled" : "❌ Disabled"} Crashlytics collection',
      );
    } catch (e) {
      debugPrint('⚠️ Failed to set Crashlytics collection enabled: $e');
    }
  }
}
