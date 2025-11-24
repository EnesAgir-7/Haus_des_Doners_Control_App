import 'package:flutter/material.dart';

import '../app_env.dart';
import '../core/console.dart';
import '../core/constants/app_constants.dart';
import '../helpers/app_helpers.dart';
import 'fcm_helper.dart';
import 'remote_config_service.dart';

class NotificationHelper {
  NotificationHelper._();

  static final NotificationHelper instance = NotificationHelper._();

  final remoteConfig = RemoteConfigService();

  FCMHelper fcmHelper = FCMHelper();
  Future<bool> sendToInspector({
    required String inspectorId,
    required BuildContext context,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    List<String>? fcmTokens,
  }) async {
    try {
      if (remoteConfig.enableNotifications == false) return false;
      final inspectorTokens =
          fcmTokens?.where((t) => t.isNotEmpty).toList() ??
          await getInspectorTokens(inspectorId, context);

      // 2️⃣ Validate tokens
      if (inspectorTokens.isEmpty) {
        console('⚠️ No FCM tokens found for inspector $inspectorId');
        return false; // Stop here
      }

      console(
        '📤 Sending notification to inspector $inspectorId (${inspectorTokens.length} device(s))',
      );

      final result = await _sendNotificationToMultipleTokens(
        fcmTokens: inspectorTokens,
        title: title,
        body: body,
        data: {
          ...data,
          'inspectorId': inspectorId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // 4️⃣ Log result
      if (result['success'] == true) {
        console(
          '✅ Notification sent: ${result['successCount']} success, ${result['failureCount']} failed',
        );
        return true;
      } else {
        console('⚠️ Notification failed to send');
        return false;
      }
    } catch (e) {
      console('⚠️ Failed to send notification to inspector $inspectorId: $e');
      return false;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      final envTopic = _getEnvTopic(topic);
      await fcmHelper.messaging.subscribeToTopic(envTopic);
      console('Subscribed to topic: $envTopic');
    } catch (e) {
      console('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      final envTopic = _getEnvTopic(topic);
      await fcmHelper.messaging.unsubscribeFromTopic(envTopic);
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
    } else if (role == AppConstants.branch) {
      await subscribeToTopic(AppConstants.branch);
    } else if (role == AppConstants.inspector) {
      await subscribeToTopic(AppConstants.inspectorTopic);
    }
  }

  /// Unsubscribe from all topics
  Future<void> unsubscribeFromAllTopics(String role) async {
    await unsubscribeFromTopic(AppConstants.allUsersTopic);
    if (role == AppConstants.admin)
      await unsubscribeFromTopic(AppConstants.adminTopic);
    if (role == AppConstants.inspector)
      await unsubscribeFromTopic(AppConstants.inspectorTopic);

    if (role == AppConstants.branch)
      await unsubscribeFromTopic(AppConstants.branch);
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
      if (remoteConfig.enableNotifications == false) return false;
      final callable = fcmHelper.functions.httpsCallable(
        'sendNotificationToToken',
      );

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
    if (remoteConfig.enableNotifications == false) return false;
    try {
      final envTopic = _getEnvTopic(topic);
      final callable = fcmHelper.functions.httpsCallable(
        'sendNotificationToTopic',
      );

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
  Future<Map<String, dynamic>> _sendNotificationToMultipleTokens({
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

      final callable = fcmHelper.functions.httpsCallable(
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
}
