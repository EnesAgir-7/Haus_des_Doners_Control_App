import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';

import '../app_env.dart';
import '../core/console.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  console('Background message received: ${message.messageId}');
  // ✅ Don't show notification here - system handles it automatically
}

class FCMHelper {
  // Singleton instance
  static final FCMHelper _instance = FCMHelper._internal();
  factory FCMHelper() => _instance;
  FCMHelper._internal();

  static FCMHelper get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  FirebaseMessaging get messaging => _messaging;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  late final FirebaseFunctions _functions;

  String? _fcmToken;
  bool _isInitialized = false;


  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize FCM
  Future<void> initialize({
    required Function(RemoteMessage) onMessageReceived,
    Function(RemoteMessage)? onMessageOpenedApp,
  }) async {
    if (_isInitialized) {
      console('FCM already initialized');
      return;
    }

    try {
      // Initialize Cloud Functions with region (optional)
      _functions = FirebaseFunctions.instance;

      // Use emulator in dev (optional - uncomment if using emulator)
      if (AppEnvironment.isDev) {
        // _functions.useFunctionsEmulator('localhost', 5001);
      }

      // Request permission (iOS)
      await _requestPermission();

      // ✅ Initialize local notifications WITH tap handling
      await _initializeLocalNotifications(onMessageOpenedApp);

      // Configure background handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      console('FCM Token: $_fcmToken');

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        console('FCM Token refreshed: $newToken');
      });

      // ✅ FIXED: Handle foreground messages WITHOUT showing local notification
      // System now handles display automatically via notification payload
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        console('Foreground message received: ${message.messageId}');

        await _showLocalNotification(message);
        // Just call the callback for data handling
        onMessageReceived(message);
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        console('Notification opened app: ${message.messageId}');
        if (onMessageOpenedApp != null) {
          onMessageOpenedApp(message);
        }
      });

      // Check for initial message (app opened from terminated state)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null && onMessageOpenedApp != null) {
        onMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
      console('FCM initialized successfully');
    } catch (e) {
      console('FCM initialization error: $e');
      rethrow;
    }
  }

  /// Request notification permission (iOS & Android 13+)
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    console('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications(
    Function(RemoteMessage)? onMessageOpenedApp,
  ) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ✅ ADD: Handle notification tap
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && onMessageOpenedApp != null) {
          try {
            final data = jsonDecode(response.payload!);
            // Create a fake RemoteMessage for consistency
            final message = RemoteMessage(
              data: Map<String, dynamic>.from(data),
            );
            onMessageOpenedApp(message);
          } catch (e) {
            console('Error parsing notification payload: $e');
          }
        }
      },
    );

    // ✅ CRITICAL: Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
      showBadge: true,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// ⚠️ KEEP THIS METHOD but it won't be called for regular notifications
  /// Only use this for custom local notifications if needed
  Future<void> _showLocalNotification(RemoteMessage message) async {
    console("Showing local notification");
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,

          icon: '@mipmap/launcher_icon', // ✅ Your app icon
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title =
        message.data['title'] ??
        message.notification?.title ??
        'New Notification';
    final body = message.data['body'] ?? message.notification?.body ?? '';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      final envTopic = _getEnvTopic(topic);
      await _messaging.subscribeToTopic(envTopic);
      console('Subscribed to topic: $envTopic');
    } catch (e) {
      console('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      final envTopic = _getEnvTopic(topic);
      await _messaging.unsubscribeFromTopic(envTopic);
      console('Unsubscribed from topic: $envTopic');
    } catch (e) {
      console('Failed to unsubscribe from topic: $e');
    }
  }

  /// Subscribe user based on role
  Future<void> subscribeUserToRoleTopics(String role) async {
    await subscribeToTopic(AppConstants.allUsersTopic);

    if (role == AppConstants.admin) {
      await subscribeToTopic(AppConstants.adminTopic);
    } else if (role == AppConstants.inspector) {
      await subscribeToTopic(AppConstants.inspectorTopic);
    }
  }

  /// Unsubscribe from all topics
  Future<void> unsubscribeFromAllTopics(String role) async {
    await unsubscribeFromTopic(AppConstants.allUsersTopic);
    if (role == AppConstants.admin) await unsubscribeFromTopic(AppConstants.adminTopic);
    if (role == AppConstants.inspector)
      await unsubscribeFromTopic(AppConstants.inspectorTopic);
  }

  /// Get environment-prefixed topic
  String _getEnvTopic(String topic) {
    final prefix = AppEnvironment.isDev ? 'dev_' : 'prod_';
    return '$prefix$topic';
  }

  /// Send notification to specific FCM token via Cloud Function
  Future<bool> sendNotificationToToken({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNotificationToToken');

      final result = await callable.call({
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      if (result.data['success'] == true) {
        console('Notification sent: ${result.data['messageId']}');
        return true;
      } else {
        console('Failed to send notification');
        return false;
      }
    } catch (e) {
      console('Error sending notification: $e');
      return false;
    }
  }

  /// Send notification to topic via Cloud Function
  Future<bool> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final envTopic = _getEnvTopic(topic);
      final callable = _functions.httpsCallable('sendNotificationToTopic');

      final result = await callable.call({
        'topic': envTopic,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      if (result.data['success'] == true) {
        console('Topic notification sent: ${result.data['messageId']}');
        return true;
      } else {
        console('Failed to send topic notification');
        return false;
      }
    } catch (e) {
      console('Error sending topic notification: $e');
      return false;
    }
  }

  /// Send notifications to multiple tokens (batch)
  Future<Map<String, dynamic>> sendNotificationToMultipleTokens({
    required List<String> fcmTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // ✅ Remove duplicates on client side too (belt and suspenders)
      final uniqueTokens = fcmTokens.toSet().toList();

      if (uniqueTokens.length != fcmTokens.length) {
        console(
          '⚠️ Removed ${fcmTokens.length - uniqueTokens.length} duplicate tokens',
        );
      }

      final callable = _functions.httpsCallable(
        'sendNotificationToMultipleTokens',
      );

      final result = await callable.call({
        'fcmTokens': uniqueTokens,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      if (result.data['success'] == true) {
        console(
          'Batch sent: ${result.data['successCount']} success, ${result.data['failureCount']} failed',
        );
        if (result.data['originalTokenCount'] !=
            result.data['uniqueTokenCount']) {
          console(
            '⚠️ Server removed ${result.data['originalTokenCount'] - result.data['uniqueTokenCount']} duplicate tokens',
          );
        }
        return result.data as Map<String, dynamic>;
      } else {
        console('Failed to send batch notification');
        return {'success': false};
      }
    } catch (e) {
      console('Error sending batch notification: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      console('FCM token deleted');
    } catch (e) {
      console('Failed to delete FCM token: $e');
    }
  }
}
