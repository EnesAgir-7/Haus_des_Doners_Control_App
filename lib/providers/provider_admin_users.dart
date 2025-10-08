import 'package:flutter/material.dart';
import '../firebase_services/firebase_user_service.dart';
import '../firebase_services/firebase_branch_service.dart';
import '../firebase_services/firebase_auth_service.dart';
import '../models/user_model.dart';
import '../models/branch_model.dart';

class ProviderAdminUsers extends ChangeNotifier {
  final UserService _userService = UserService();
  final BranchService _branchService = BranchService();
  final FirebaseAuthHelper _authHelper = FirebaseAuthHelper();
  List<UserModel> _users = [];
  Map<String, List<BranchModel>> _userBranches = {};
  List<BranchModel>? _allBranches;
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

      // Load branches for inspectors
      for (var user in _users.where((u) => u.isInspector)) {
        final branches = await _branchService.getInspectorBranches(user.id);
        _userBranches[user.id] = branches;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<BranchModel> getUserBranches(String userId) {
    return _userBranches[userId] ?? [];
  }

  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _userService.updateUser(userId, data);
      final updatedUser = await _userService.getUserById(userId);
      if (updatedUser != null) {
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = updatedUser;
          notifyListeners();
          return updatedUser;
        }
      }
      throw Exception('User not found');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BranchModel>> getUnassignedBranches() async {
    try {
      if (_allBranches == null) {
        final snapshot = await _branchService.getAllBranches();
        _allBranches = snapshot;
      }
      return _allBranches!.where((branch) => !branch.isRouteAssigned).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignBranchToUser(String userId, String branchId) async {
    try {
      // Get the user and branch
      final user = _users.firstWhere((u) => u.id == userId);
      final branch = _allBranches?.firstWhere((b) => b.id == branchId);

      if (branch == null) throw Exception('Branch not found');

      // Update branch in Firestore with assignedInspector map
      await _branchService.updateBranch(
        branch.copyWith(
          assignedInspector: AssignedInspector(id: user.id, name: user.name),
          isRouteAssigned: true,
        ),
      );

      // Update assignedInspector field directly in Firestore
      await _branchService.updateBranchAssignedInspector(branchId, {
        'id': user.id,
        'name': user.name,
      });

      // Update local state
      final index = _allBranches?.indexWhere((b) => b.id == branchId) ?? -1;
      if (index != -1) {
        _allBranches![index] = _allBranches![index].copyWith(
          assignedInspector: AssignedInspector(id: user.id, name: user.name),
          isRouteAssigned: true,
        );
      }

      // Update user branches
      final userBranches = _userBranches[userId] ?? [];
      userBranches.add(branch);
      _userBranches[userId] = userBranches;

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? region,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final userId = await _authHelper.createUser(
        email: email,
        password: password,
      );

      // 2. Create user in Firestore
      final user = UserModel(
        id: userId,
        name: name,
        email: email,
        role: role,
        active: true,
        region: region,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _userService.createUser(userId, user);

      // 3. Add user to local state
      _users.add(user);
      notifyListeners();
    } catch (e) {
      rethrow;
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
