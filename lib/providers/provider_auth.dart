import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../firebase_services/firebase_auth_service.dart';
import '../firebase_services/firebase_error_helper.dart';
import '../helpers/local_storage_helper.dart';
import '../models/user_model.dart';

class ProviderAuth extends ChangeNotifier {
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  UserModel? userModel;

  ProviderAuth() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      if (user == null) {
        userModel = null;
      }
      notifyListeners();
    });
  }

  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String? get error => _error;

  /// Fetches the user model from Firestore
  Future<UserModel?> fetchUserModel() async {
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
      if (_user == null) {
        debugPrint("⚠️ No authenticated user found.");
        return null;
      }

      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (!doc.exists) {
        debugPrint("⚠️ User document not found for UID: ${_user!.uid}");
        return null;
      }
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

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authHelper.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await LocalStorageHelper.instance.removeData(cacheUserKey);
    await _authHelper.signOut();
    userModel = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
