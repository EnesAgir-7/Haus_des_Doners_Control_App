import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../common_services/firebase_auth_service.dart';
import '../../../common_services/firebase_error_helper.dart';
import '../../../helpers/local_storage_helper.dart';
import '../../../models/user_model.dart';

class ProviderAuth extends ChangeNotifier {
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  UserModel? userModel;
  bool _isFetchingUserModel = false;

  ProviderAuth() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _handleAuthStateChange(user);
    });
  }

  User? get currentUser => _user;
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

  Future<void> _handleAuthStateChange(User? user) async {
    _user = user;

    if (user == null) {
      // Logout
      userModel = null;
      loggedInUser = null;
      await LocalStorageHelper.instance.removeData(cacheUserKey);
    } else {
      // Login or already logged in
      if (!_isFetchingUserModel) {
        _isFetchingUserModel = true;
        final fetchedUser = await fetchUserModel();
        userModel = fetchedUser;
        loggedInUser = fetchedUser;
        _isFetchingUserModel = false;
      }
    }

    notifyListeners();
  }

  Future<UserModel?> fetchUserModel() async {
    // Avoid fetching if cached and same UID
    if (userModel != null && _user != null && userModel!.id == _user!.uid) {
      return userModel;
    }

    // Try cached data first
    final cachedMap = await LocalStorageHelper.instance.getData(cacheUserKey);
    if (cachedMap != null) {
      try {
        userModel = UserModel.fromMap(cachedMap);
        return userModel;
      } catch (e) {
        debugPrint("⚠️ Failed to parse cached user: $e");
      }
    }

    final fetchedUser = await FirebaseSafeRunner.run<UserModel?>(() async {
      if (_user == null) return null;

      var doc = await _firestore
          .collection(Collections.inspectors)
          .doc(_user!.uid)
          .get();

      if (!doc.exists) {
        doc = await _firestore
            .collection(Collections.admins)
            .doc(_user!.uid)
            .get();
      }

      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    });

    if (fetchedUser != null) {
      userModel = fetchedUser;
      await LocalStorageHelper.instance.saveData(
        cacheUserKey,
        fetchedUser.toMap(),
      );
    }

    return userModel;
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authHelper.signIn(email: email, password: password);
      if (user != null) {
        await fetchUserModel();

        if (userModel == null) {
          _error = "User profile not found. Please contact support.";
          await _authHelper.signOut();
          return false;
        }

        loggedInUser = userModel;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    userModel = null;
    loggedInUser = null;
    await LocalStorageHelper.instance.removeData(cacheUserKey);
    await _authHelper.signOut();
    notifyListeners();
  }
}
