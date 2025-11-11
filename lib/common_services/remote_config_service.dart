import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:haus_des_control/app_env.dart';

import '../core/constants/app_constants.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;

  late final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService._internal();

  /// Initialize Remote Config with default values and fetch latest
  Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    // ✅ Configure fetch behavior BEFORE anything else
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: AppEnvironment.isProd
            ? const Duration(hours: 1)
            : Duration.zero,
      ),
    );

    await _remoteConfig.setDefaults({
      AppConstants.showInspectorNotification: true,
      AppConstants.enableNotifications: true,
      AppConstants.inspectorBranchEdit: true,
      AppConstants.useOldHome: false,
      AppConstants.showInspectorHomeGraph: true,
      AppConstants.showBroadCastNotification: true,
    });

    try {
      // Fetch and activate latest config
      await _remoteConfig.fetchAndActivate();
      debugPrint('✅ Remote Config fetched and activated successfully');
    } catch (e) {
      debugPrint('⚠️ Remote Config fetch failed: $e');
    }
  }

  /// ---- Flags ----
  bool get showInspectorNotification =>
      _remoteConfig.getBool(AppConstants.showInspectorNotification);
  bool get inspectorBranchEdit =>
      _remoteConfig.getBool(AppConstants.inspectorBranchEdit);
  bool get showBroadCastNotification =>
      _remoteConfig.getBool(AppConstants.showBroadCastNotification);

  bool get enableNotifications =>
      _remoteConfig.getBool(AppConstants.enableNotifications);
  bool get showInspectorHomeGraph =>
      _remoteConfig.getBool(AppConstants.showInspectorHomeGraph);
  bool get useOldHome =>
      _remoteConfig.getBool(AppConstants.useOldHome);

  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('🔄 Remote Config refreshed.');
    } catch (e) {
      debugPrint('⚠️ Remote Config refresh failed: $e');
    }
  }
}
