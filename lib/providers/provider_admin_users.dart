import 'package:flutter/material.dart';
import '../firebase_services/firebase_user_service.dart';
import '../models/user_model.dart';

class ProviderAdminUsers extends ChangeNotifier {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  String? _error;
  bool _isLoading = false;
  String _searchQuery = '';

  List<UserModel> get users => _users
      .where(
        (user) =>
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
      .toList();

  List<UserModel> get inspectors =>
      _users.where((user) => user.role.toLowerCase() == 'inspector').toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadUsers(String currentUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
    final allUsers = await _userService.getAllUsers();
    print('Fetched ${allUsers.length} users from Firebase');
    _users = allUsers.where((user) => user.id != currentUserId).toList();
    print('Filtered to ${_users.length} users (excluding current user)');
    _error = null;
    } catch (e) {
    _error = e.toString();
    } finally {
    _isLoading = false;
    notifyListeners();
  }
  }

  Future<void> toggleUserActive(String userId, bool active) async {
    try {
      await _userService.updateUser(userId, {'active': active});
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        final updatedUser = await _userService.getUserById(userId);
        if (updatedUser != null) {
          _users[userIndex] = updatedUser;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
