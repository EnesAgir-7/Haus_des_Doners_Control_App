import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../common_services/firebase_auth_service.dart';
import '../../../common_services/notification_helper.dart';
import '../../../core/console.dart';
import '../../../helpers/local_storage_helper.dart';
import '../../../models/user_model.dart';
import '../../../translations/locale_keys.g.dart';

class ProviderAuth extends ChangeNotifier {
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  UserModel? userModel;
  StreamSubscription? _tokenRefreshSubscription;

  // ✅ NEW: Prevent concurrent token operations
  bool _isUpdatingToken = false;

  ProviderAuth() {
    _loadCachedUser();
  }

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String? get error => _error;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _loadCachedUser() async {
    final cachedMap = await LocalStorageHelper.instance.getData(cacheUserKey);
    if (cachedMap != null) {
      try {
        userModel = UserModel.fromMap(cachedMap);
        loggedInUser = userModel;

        // ✅ FIXED: Only start listener if FCM is initialized
        // Don't add token here - will be handled by token refresh if needed
        if (FCMHelper.instance.isInitialized) {
          _startTokenRefreshListener();
        }

        notifyListeners();
      } catch (e) {
        await LocalStorageHelper.instance.removeData(cacheUserKey);
      }
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authHelper.signIn(email: email, password: password);
      if (user == null) {
        _error = LocaleKeys.loginFailed.tr();
        return false;
      }

      // Fetch from Firestore
      var doc = await _firestore
          .collection(Collections.inspectors)
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        doc = await _firestore
            .collection(Collections.admins)
            .doc(user.uid)
            .get();
      }

      if (!doc.exists) {
        _error = LocaleKeys.userProfileNotFound.tr();
        await _authHelper.signOut();
        return false;
      }

      userModel = UserModel.fromFirestore(doc);
      loggedInUser = userModel;

      // Subscribe to FCM topics based on role
      await FCMHelper.instance.subscribeUserToRoleTopics(userModel!.role);

      // ✅ FIXED: Start listener BEFORE adding token to prevent race condition
      _startTokenRefreshListener();

      // ✅ FIXED: Add a small delay to ensure listener is active
      await Future.delayed(const Duration(milliseconds: 100));

      // Add current device's FCM token to the array
      final fcmToken = FCMHelper.instance.fcmToken;
      if (fcmToken != null) {
        await _addFCMToken(user.uid, fcmToken, userModel!.role);
      } else {
        console('FCM token not available during login', type: DebugType.alert);
      }

      await LocalStorageHelper.instance.saveData(
        cacheUserKey,
        userModel!.toMap(),
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to FCM token refresh and update in Firestore
  void _startTokenRefreshListener() {
    // ✅ FIXED: Cancel existing subscription first
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    // Only listen if user is logged in and FCM is initialized
    if (userModel != null && FCMHelper.instance.isInitialized) {
      console('🎧 Starting FCM token refresh listener');

      _tokenRefreshSubscription = FCMHelper.instance.messaging.onTokenRefresh
          .listen((newToken) async {
            console('🔄 FCM token refreshed: $newToken');

            if (userModel != null && !_isUpdatingToken) {
              // Get old token to replace it
              final oldToken = FCMHelper.instance.fcmToken;
              if (oldToken != null && oldToken != newToken) {
                await _replaceFCMToken(
                  userModel!.id,
                  oldToken,
                  newToken,
                  userModel!.role,
                );
              } else {
                await _addFCMToken(userModel!.id, newToken, userModel!.role);
              }
            }
          });
    }
  }

  /// Add FCM token to the user's token array (multi-device support)
  Future<void> _addFCMToken(String uid, String token, String role) async {
    // ✅ FIXED: Prevent concurrent operations
    if (_isUpdatingToken) {
      console('⏳ Token update already in progress, skipping...');
      return;
    }

    _isUpdatingToken = true;

    try {
      final collection = role == 'admin'
          ? Collections.admins
          : Collections.inspectors;

      // ✅ FIXED: Use transaction to prevent race conditions
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection(collection).doc(uid);
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          console('❌ User document not found', type: DebugType.error);
          return;
        }

        final currentTokens = List<String>.from(
          doc.data()?[UserFields.fcmTokens] ?? [],
        );

        if (currentTokens.contains(token)) {
          console('ℹ️ FCM token already exists, skipping add');
          return;
        }

        // Add token
        currentTokens.add(token);

        transaction.update(docRef, {
          UserFields.fcmTokens: currentTokens,
          UserFields.updatedAt: FieldValue.serverTimestamp(),
        });

        console('✅ FCM token added successfully for user: $uid');
      });

      // ✅ Update local models AFTER successful Firestore update
      if (!userModel!.fcmTokens!.contains(token)) {
        userModel?.fcmTokens?.add(token);
        loggedInUser?.fcmTokens?.add(token);
        await LocalStorageHelper.instance.saveData(
          cacheUserKey,
          userModel!.toMap(),
        );
      }
    } catch (e) {
      console('❌ Failed to add FCM token: $e', type: DebugType.error);
    } finally {
      _isUpdatingToken = false;
    }
  }

  Future<void> _replaceFCMToken(
    String uid,
    String oldToken,
    String newToken,
    String role,
  ) async {
    // ✅ FIXED: Prevent concurrent operations
    if (_isUpdatingToken) {
      console('⏳ Token update already in progress, skipping...');
      return;
    }

    _isUpdatingToken = true;

    try {
      final collection = role == 'admin'
          ? Collections.admins
          : Collections.inspectors;

      // ✅ FIXED: Use transaction for atomic operation
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection(collection).doc(uid);
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          console('❌ User document not found', type: DebugType.error);
          return;
        }

        final currentTokens = List<String>.from(
          doc.data()?[UserFields.fcmTokens] ?? [],
        );

        // Remove old token and add new one
        currentTokens.remove(oldToken);
        if (!currentTokens.contains(newToken)) {
          currentTokens.add(newToken);
        }

        transaction.update(docRef, {
          UserFields.fcmTokens: currentTokens,
          UserFields.updatedAt: FieldValue.serverTimestamp(),
        });

        console('✅ FCM token replaced successfully for user: $uid');
      });

      // ✅ Update local models
      userModel?.fcmTokens?.remove(oldToken);
      loggedInUser?.fcmTokens?.remove(oldToken);
      if (!userModel!.fcmTokens!.contains(newToken)) {
        userModel?.fcmTokens?.add(newToken);
        loggedInUser?.fcmTokens?.add(newToken);
      }

      await LocalStorageHelper.instance.saveData(
        cacheUserKey,
        userModel!.toMap(),
      );
    } catch (e) {
      console('❌ Failed to replace FCM token: $e', type: DebugType.error);
    } finally {
      _isUpdatingToken = false;
    }
  }

  /// Remove only the current device's FCM token
  Future<void> _removeFCMToken(String uid, String token, String role) async {
    try {
      final collection = role == 'admin'
          ? Collections.admins
          : Collections.inspectors;

      // ✅ Use transaction for consistency
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection(collection).doc(uid);
        final doc = await transaction.get(docRef);

        if (!doc.exists) return;

        final currentTokens = List<String>.from(
          doc.data()?[UserFields.fcmTokens] ?? [],
        );

        currentTokens.remove(token);

        transaction.update(docRef, {
          UserFields.fcmTokens: currentTokens,
          UserFields.updatedAt: FieldValue.serverTimestamp(),
        });
      });

      // Update local models
      userModel?.fcmTokens?.remove(token);
      loggedInUser?.fcmTokens?.remove(token);
      await LocalStorageHelper.instance.saveData(
        cacheUserKey,
        userModel!.toMap(),
      );

      console('✅ FCM token removed successfully for user: $uid');
    } catch (e) {
      console('❌ Failed to remove FCM token: $e', type: DebugType.error);
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ Cancel token refresh listener FIRST
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      // Unsubscribe from topics
      if (userModel != null) {
        await FCMHelper.instance.unsubscribeFromAllTopics(userModel!.role);
      }

      // Remove ONLY current device's FCM token (not all tokens!)
      final currentToken = FCMHelper.instance.fcmToken;
      if (userModel != null && currentToken != null) {
        await _removeFCMToken(userModel!.id, currentToken, userModel!.role);
      }

      userModel = null;
      loggedInUser = null;
      await _authHelper.signOut();
      await LocalStorageHelper.instance.removeData(cacheUserKey);
    } catch (e) {
      console('❌ Logout error: $e', type: DebugType.error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}
