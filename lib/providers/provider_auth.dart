import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_helpers/firebase_auth_helper.dart';

class ProviderAuth extends ChangeNotifier {
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  User? _user;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  ProviderAuth() {
    // Listen to Firebase auth changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
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
    await _authHelper.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
