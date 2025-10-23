import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haus_des_control/core/console.dart';

import '../../../models/branch_model.dart';
import '../../../models/user_model.dart';
import '../admin_firebase_services/admin_branch_service.dart';

class ProviderAdminBranches with ChangeNotifier {
  final AdminBranchService _branchService = AdminBranchService();

  List<BranchModel> _branches = [];
  List<UserModel> _inspectors = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _error;

  StreamSubscription<List<BranchModel>>? _branchesSubscription;

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

  // 🔹 Stream all branches in real-time (avoid redundant listeners)
  void loadBranchStream() {
    if (_branchesSubscription != null) {
      print("✅ Branch stream already active — skipping reinitialization");
      return;
    }

    print("📡 Initializing branch stream...");

    _setLoading(true);
    _error = null;

    _branchesSubscription = _branchService.streamAllBranches().listen(
      (branchList) {
        _branches = branchList;
        _error = null;
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _error = 'Branches stream error: $error';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  // 🔹 Cancel branch stream when not needed
  Future<void> cancelBranchStream() async {
    await _branchesSubscription?.cancel();
    _branchesSubscription = null;
    print("🛑 Branch stream cancelled");
  }

  // Assign inspector to branch
  Future<void> updateBranch(BranchModel branch) async {
    _setLoading(true);
    _error = null;

    try {
      await _branchService.updateBranch(branch);
    } catch (e) {
      _error = 'Error updating branch: $e';
    } finally {
      _setLoading(false);
    }
  }


Future<bool> updateBrachTemplate({
    required String branchId,
    required String templateId,
    required String templateName,
  }) async {
    try {
      console('Updating branch template...');
      await  _branchService.updateBranchTemplate(
        branchId: branchId,
        templateId: templateId,
        templateName: templateName,
      );
      return true;
    } catch (e) {
      console('❌ Error updating template: $e');
      return false; 
    } finally {
    }
  }

Future<bool> assignInspectorToBranch({
    required String branchId,
    required String inspectorId,
    required String inspectorName,
  }) async {
    _setLoading(true);
    try {
      console('Assigning branch to inspector...');
      await _branchService.assignBranchToInspector(
        inspectorId: inspectorId,
        inspectorName: inspectorName,
        branchId: branchId,
      );
      return true; // ✅ Success
    } catch (e) {
      console('❌ Error assigning branch: $e');
      return false; // ❌ Failure
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> unassignInspectorFromBranch({
    required String branchId,
    required String inspectorId,
  }) async {
    _setLoading(true);
    try {
      console('Unassigning branch from inspector...');
      await _branchService.removeBranchFromInspector(
        branchId: branchId,
        inspectorId: inspectorId,
      );
      return true; // ✅ Success
    } catch (e) {
      console('❌ Error unassigning branch: $e');
      return false; // ❌ Failure
    } finally {
      _setLoading(false);
    }
  }


  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 🔹 Dispose stream safely when provider is destroyed
  @override
  void dispose() {
    _branchesSubscription?.cancel();
    super.dispose();
  }
}
