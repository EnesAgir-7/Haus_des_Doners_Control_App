import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../common_services/firebase_auth_service.dart';
import '../../../helpers/local_storage_helper.dart';
import '../../../models/user_model.dart';

class ProviderAuth extends ChangeNotifier {
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  UserModel? userModel;

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
        _error = "Login failed";
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
        _error = "User profile not found";
        await _authHelper.signOut();
        return false;
      }

      userModel = UserModel.fromFirestore(doc);
      loggedInUser = userModel;

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

  Future<void> logout() async {
    userModel = null;
    loggedInUser = null;
    await _authHelper.signOut();
    await LocalStorageHelper.instance.removeData(cacheUserKey);
    notifyListeners();
  }
}
