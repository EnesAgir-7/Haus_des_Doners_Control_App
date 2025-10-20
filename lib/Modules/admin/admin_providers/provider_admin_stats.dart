import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProviderAdminStats extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;
  int _totalBranches = 0;
  int _totalUsers = 0;
  int _totalTasks = 0;
  int _totalFleet = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalBranches => _totalBranches;
  int get totalUsers => _totalUsers;
  int get totalTasks => _totalTasks;
  int get totalFleet => _totalFleet;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get total branches count
      final branchesSnapshot = await _firestore.collection('branches').get();
      _totalBranches = branchesSnapshot.size;

      // Get total non-admin users count
      final usersSnapshot = await _firestore.collection('inspectors').get();
      _totalUsers = usersSnapshot.size;

      // Get total vehicles count
      final vehiclesSnapshot = await _firestore.collection('vehicles').get();
      _totalFleet = vehiclesSnapshot.size;

      // Get total tasks count
      final tasksSnapshot = await _firestore.collection('tasks').get();
      _totalTasks = tasksSnapshot.size;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
