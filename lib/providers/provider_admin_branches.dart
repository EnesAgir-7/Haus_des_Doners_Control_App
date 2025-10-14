import 'package:flutter/material.dart';
import '../firebase_services/firebase_branch_service.dart';
import '../firebase_services/firebase_user_service.dart';
import '../models/branch_model.dart';
import '../models/user_model.dart';

class ProviderAdminBranches with ChangeNotifier {
  final BranchService _branchService = BranchService();
  final UserService _userService = UserService();

  List<BranchModel> _branches = [];
  List<UserModel> _inspectors = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _error;

  // Getters
  List<BranchModel> get branches => _filterBranches();
  List<UserModel> get inspectors => _inspectors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter branches based on search query
  List<BranchModel> _filterBranches() {
    if (_searchQuery.isEmpty) return _branches;
    return _branches.where((branch) {
      final searchLower = _searchQuery.toLowerCase();
      return branch.name.toLowerCase().contains(searchLower) ||
          branch.address.toLowerCase().contains(searchLower);
    }).toList();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Load all branches and inspectors
  Future<void> loadData() async {
    _setLoading(true);
    _error = null;

    try {
      // Load branches and inspectors in parallel
      final results = await Future.wait([
        _branchService.streamAllBranches().first,
        _userService.getActiveInspectors(),
      ]);

      _branches = results[0] as List<BranchModel>;
      _inspectors = results[1] as List<UserModel>;
    } catch (e) {
      _error = 'Error loading data: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Stream branches and inspectors
  Stream<void> streamData() {
    return Stream.periodic(
      const Duration(seconds: 30),
    ).asyncMap((_) => loadData());
  }

  // Assign inspector to branch
  Future<void> updateBranch(BranchModel branch) async {
    _setLoading(true);
    _error = null;

    try {
      await _branchService.updateBranch(branch);
      await loadData(); // Reload data to get updated branch
    } catch (e) {
      _error = 'Error updating branch: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> assignInspectorToBranch(
    String branchId,
    String inspectorId,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      if (inspectorId.isEmpty) {
        await _branchService.removeBranchAssignment(
          inspectorId: inspectorId,
          branchId: branchId,
        );
      } else {
        final branch = _branches.firstWhere((b) => b.id == branchId);
        final inspector = _inspectors.firstWhere((i) => i.id == inspectorId);
        await _branchService.assignBranchToHimself(
          branchAddress: branch.address,
          branchTemplateId: branch.templateId,
          inspectorId: inspectorId,
          inspectorName: inspector.name,
          branchId: branchId,
          branchName: branch.name,
          timeSlot: DateTime.now().hour.toString().padLeft(2, '0') + ':00',
        );
      }
      await loadData(); // Reload data to get updated assignments
    } catch (e) {
      _error = 'Error assigning inspector: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
