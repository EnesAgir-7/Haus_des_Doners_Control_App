import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  FirebaseFunctions get functions => _functions;

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

        if (Platform.isAndroid) {
          await _showLocalNotification(message);
        }

        // Just call the callback for data handling
        onMessageReceived(message);
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        console('Notification opened app: ${message.messageId}');
        // ✅ RESET BADGE WHEN NOTIFICATION TRAPS THE APP
        resetBadgeCount();

        if (onMessageOpenedApp != null) {
          onMessageOpenedApp(message);
        }
      });

      // Check for initial message (app opened from terminated state)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        // ✅ RESET BADGE WHEN OPENED FROM INITIAL MESSAGE
        await resetBadgeCount();

        if (onMessageOpenedApp != null) {
          onMessageOpenedApp(initialMessage);
        }
      }

      _isInitialized = true;
      console('FCM initialized successfully');

      // ✅ RESET BADGE ON INITIALIZATION
      await resetBadgeCount();
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

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
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
      presentBanner: true,
      presentList: true,
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

  /// ✅ Reset app icon badge count (specifically for iOS)
  Future<void> resetBadgeCount() async {
    if (!Platform.isIOS) return;

    try {
      console('Resetting app icon badge count');
      final dynamic platformPlugin = _localNotifications
          .resolvePlatformSpecificImplementation();

      if (platformPlugin != null) {
        try {
          await platformPlugin.clearBadge();
          console('Badge cleared using clearBadge()');
          return;
        } catch (_) {}
        try {
          await platformPlugin.setApplicationIconBadgeNumber(0);
          console('Badge cleared using setApplicationIconBadgeNumber(0)');
          return;
        } catch (_) {}
      }
    } catch (e) {
      console('Failed to reset badge count: $e');
    }
  }
}
