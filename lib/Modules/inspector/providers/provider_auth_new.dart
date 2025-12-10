import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../common_services/firebase_auth_service.dart';
import '../../../common_services/fcm_helper.dart';
import '../../../common_services/notification_helper.dart';
import '../../../core/console.dart';
import '../../../core/constants/app_constants.dart';
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

  // ✅ Prevent duplicate operations
  String? _lastSyncedToken;
  bool _isSyncing = false;

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

        // Start listener for cached user
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

      // ✅ ALL users are now in the inspectors collection
      final doc = await _firestore
          .collection(Collections.inspectors)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        _error = LocaleKeys.userProfileNotFound.tr();
        await _authHelper.signOut();
        return false;
      }

      userModel = UserModel.fromFirestore(doc);
      loggedInUser = userModel;

      // Subscribe to FCM topics based on role
      await NotificationHelper.instance.subscribeUserToRoleTopics(
        userModel!.role,
      );

      // Start listener FIRST (before sync)
      _startTokenRefreshListener();

      // Sync FCM token
      final fcmToken = FCMHelper.instance.fcmToken;
      if (fcmToken != null) {
        await _syncFCMToken(user.uid, fcmToken, userModel!.role);
      } else {
        console('⚠️ FCM token not available');
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

  void _startTokenRefreshListener() {
    // Cancel existing subscription
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    if (userModel == null || !FCMHelper.instance.isInitialized) return;

    console('🎧 Token listener started');

    _tokenRefreshSubscription = FCMHelper.instance.messaging.onTokenRefresh
        .listen((newToken) async {
          // ✅ Skip if we just synced this token
          if (newToken == _lastSyncedToken) {
            console('⏭️ Token already synced, skipping');
            return;
          }

          console('🔄 Token refresh: $newToken');
          if (userModel != null) {
            await _syncFCMToken(userModel!.id, newToken, userModel!.role);
          }
        });
  }

  Future<void> _syncFCMToken(String uid, String token, String role) async {
    // ✅ Guard 1: Already syncing
    if (_isSyncing) {
      console('⏳ Sync in progress, skipping');
      return;
    }

    // ✅ Guard 2: Token already synced
    if (_lastSyncedToken == token &&
        userModel?.fcmTokens?.contains(token) == true) {
      console('✓ Token already synced');
      return;
    }

    _isSyncing = true;

    try {
      // ✅ Update inspectors collection for ALL user types
      await _updateInspectorCollectionTokens(uid, token);

      // ✅ For branch users ONLY, ALSO update branches collection
      if (role == AppConstants.branch) {
        await _updateBranchModelTokens(uid, token);
      }

      _lastSyncedToken = token;
      console('💾 Token synced successfully');
    } catch (e) {
      console('❌ Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ✅ Update tokens in inspectors collection (for ALL user types)
  Future<void> _updateInspectorCollectionTokens(
    String uid,
    String token,
  ) async {
    final needsUpdate = await _firestore.runTransaction<bool>((
      transaction,
    ) async {
      final docRef = _firestore.collection(Collections.inspectors).doc(uid);
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        console('❌ User doc not found in inspectors collection');
        return false;
      }

      final currentTokens = List<String>.from(
        doc.data()?[UserFields.fcmTokens] ?? [],
      );

      // ✅ Remove duplicates + add current token
      final uniqueTokens = {...currentTokens, token}.toList();

      // ✅ Only update if changed
      if (uniqueTokens.length == currentTokens.length &&
          currentTokens.contains(token)) {
        console('✓ No update needed in inspectors collection');
        return false;
      }

      transaction.update(docRef, {
        UserFields.fcmTokens: uniqueTokens,
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      });

      // ✅ Update local models inside transaction
      userModel?.fcmTokens = List.from(uniqueTokens);
      loggedInUser?.fcmTokens = List.from(uniqueTokens);

      console('✅ Updated inspectors collection: ${uniqueTokens.length} tokens');
      return true;
    });

    // ✅ Save to cache only if updated
    if (needsUpdate && userModel != null) {
      await LocalStorageHelper.instance.saveData(
        cacheUserKey,
        userModel!.toMap(),
      );
    }
  }

  // ✅ Helper method to update BranchModel tokens in branches collection ONLY
  // This is ONLY called for branch users as a secondary update
  Future<void> _updateBranchModelTokens(String userId, String token) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // ✅ Path: branches/{userId} - direct document
        final docRef = _firestore.collection(Collections.branches).doc(userId);

        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          console(
            '⚠️ Branch doc not found at branches/$userId - skipping branch sync',
          );
          return;
        }

        final currentTokens = List<String>.from(doc.data()?['fcmTokens'] ?? []);

        // ✅ Remove duplicates + add current token
        final uniqueTokens = {...currentTokens, token}.toList();

        // ✅ Only update if changed
        if (uniqueTokens.length == currentTokens.length &&
            currentTokens.contains(token)) {
          console('✓ No update needed in branches collection');
          return;
        }

        transaction.update(docRef, {
          'fcmTokens': uniqueTokens,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        console(
          '✅ Updated BranchModel at branches/$userId: ${uniqueTokens.length} tokens',
        );
      });
    } catch (e) {
      console('⚠️ Branch sync error (non-critical): $e');
      // Don't rethrow - branch sync is secondary, main sync already succeeded
    }
  }

  Future<void> _removeFCMToken(String uid, String token, String role) async {
    try {
      // ✅ Remove token from inspectors collection (for ALL user types)
      await _removeInspectorCollectionToken(uid, token);

      // ✅ For branch users ONLY, ALSO remove from branches collection
      if (role == AppConstants.branch) {
        await _removeBranchModelToken(uid, token);
      }
    } catch (e) {
      console('❌ Remove failed: $e');
    }
  }

  // ✅ Remove token from inspectors collection (for ALL user types)
  Future<void> _removeInspectorCollectionToken(String uid, String token) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(Collections.inspectors).doc(uid);
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        console('❌ User doc not found in inspectors collection');
        return;
      }

      final currentTokens = List<String>.from(
        doc.data()?[UserFields.fcmTokens] ?? [],
      );

      if (!currentTokens.contains(token)) {
        console('✓ Token already removed from inspectors collection');
        return;
      }

      final updatedTokens = currentTokens.where((t) => t != token).toList();

      transaction.update(docRef, {
        UserFields.fcmTokens: updatedTokens,
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      });

      userModel?.fcmTokens = List.from(updatedTokens);
      loggedInUser?.fcmTokens = List.from(updatedTokens);

      console('✅ Token removed from inspectors: ${updatedTokens.length} left');
    });

    if (userModel != null) {
      await LocalStorageHelper.instance.saveData(
        cacheUserKey,
        userModel!.toMap(),
      );
    }
  }

  // ✅ Helper method to remove token from BranchModel in branches collection
  // This is ONLY called for branch users as a secondary removal
  Future<void> _removeBranchModelToken(String userId, String token) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // ✅ Path: branches/{userId}
        final docRef = _firestore.collection(Collections.branches).doc(userId);
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          console(
            '⚠️ Branch doc not found at branches/$userId - skipping branch removal',
          );
          return;
        }

        final currentTokens = List<String>.from(doc.data()?['fcmTokens'] ?? []);

        if (!currentTokens.contains(token)) {
          console('✓ Token already removed from branch');
          return;
        }

        final updatedTokens = currentTokens.where((t) => t != token).toList();

        transaction.update(docRef, {
          'fcmTokens': updatedTokens,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        console(
          '✅ Token removed from BranchModel at branches/$userId: ${updatedTokens.length} left',
        );
      });
    } catch (e) {
      console('⚠️ Branch removal error (non-critical): $e');
      // Don't rethrow - branch removal is secondary, main removal already succeeded
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cancel listener
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      // Unsubscribe from topics
      if (userModel != null) {
        await NotificationHelper.instance.unsubscribeFromAllTopics(
          userModel!.role,
        );
      }

      // Remove current token
      final currentToken = FCMHelper.instance.fcmToken;
      if (userModel != null && currentToken != null) {
        await _removeFCMToken(userModel!.id, currentToken, userModel!.role);
      }

      userModel = null;
      loggedInUser = null;
      _lastSyncedToken = null;

      await _authHelper.signOut();
      await LocalStorageHelper.instance.removeData(cacheUserKey);

      console('✅ Logout complete');
    } catch (e) {
      console('❌ Logout error: $e');
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
