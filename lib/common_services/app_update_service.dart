import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'remote_config_service.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  late PackageInfo _packageInfo;
  final RemoteConfigService _remoteConfig = RemoteConfigService();

  /// Initialize the service
  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Check if a force update is required
  Future<bool> isForceUpdateRequired() async {
    try {
      // Check if force update is enabled
      if (!_remoteConfig.forceUpdateEnabled) {
        return false;
      }

      // Get current app version
      final currentVersion = _packageInfo.version;

      // Get platform-specific minimum version
      final platformMinimumVersion = Platform.isAndroid
          ? _remoteConfig.minimumVersionAndroid
          : _remoteConfig.minimumVersionIos;

      if (platformMinimumVersion.isEmpty) {
        return false;
      }

      // Compare versions
      return _isVersionOlder(currentVersion, platformMinimumVersion);
    } catch (e) {
      debugPrint('Error checking force update: $e');
      return false;
    }
  }

  /// Launch the app store for update
  Future<void> launchUpdateUrl() async {
    final updateUrl = Platform.isAndroid
        ? _remoteConfig.updateUrlAndroid
        : _remoteConfig.updateUrlIos;

    // Use platform-specific URL if available, otherwise use generic store URLs
    final finalUrl = updateUrl.isNotEmpty
        ? updateUrl
        : (Platform.isAndroid
              ? 'https://play.google.com/store/apps/details?id=com.hausdesdoners.hddcontrol'
              : 'https://apps.apple.com/app/6757006959');

    try {
      await launchUrl(
        Uri.parse(finalUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching update URL: $e');
      // Try alternative launch mode if external application fails
      try {
        await launchUrl(Uri.parse(finalUrl));
      } catch (e2) {
        debugPrint('Error launching update URL with alternative mode: $e2');
      }
    }
  }

  /// Compare two version strings (semantic versioning)
  bool _isVersionOlder(String currentVersion, String minimumVersion) {
    try {
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final minimumParts = minimumVersion.split('.').map(int.parse).toList();

      // Pad shorter version with zeros
      while (currentParts.length < 3) currentParts.add(0);
      while (minimumParts.length < 3) minimumParts.add(0);

      // Compare major, minor, patch versions
      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < minimumParts[i]) {
          return true;
        } else if (currentParts[i] > minimumParts[i]) {
          return false;
        }
      }

      return false; // Versions are equal
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  /// Get current app version
  String get currentVersion => _packageInfo.version;

  /// Get update message (hardcoded)
  String get updateMessage =>
      LocaleKeys.force_update_message.tr();
}
