import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haus_des_control/core/console.dart';

import '../../../core/constants/app_constants.dart';
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
  String _sortBy = AppConstants.name;

  List<BranchModel> get allBranches => _branches;
  StreamSubscription<List<BranchModel>>? _branchesSubscription;

  // Getters
  List<BranchModel> get branches => _filteredAndSortedBranches();
  List<UserModel> get inspectors => _inspectors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get sortBy => _sortBy;

  // Filter branches based on search query
  List<BranchModel> _filteredAndSortedBranches() {
    var filtered = List<BranchModel>.from(_branches);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((branch) {
        final searchLower = _searchQuery.toLowerCase();
        return branch.name.toLowerCase().contains(searchLower) ||
            branch.address.toLowerCase().contains(searchLower) ||
            (branch.region?.toLowerCase().contains(searchLower) ?? false) ||
            (branch.assignedInspector?.name.toLowerCase().contains(
                  searchLower,
                ) ??
                false) ||
            branch.contactName.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Sort based on selected criteria
    switch (_sortBy) {
      case AppConstants.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;

      case AppConstants.score:
        filtered.sort((a, b) {
          // Sort by average score (highest first)
          final comparison = b.averageScore.compareTo(a.averageScore);
          if (comparison != 0) return comparison;
          // If scores are equal, sort by name
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;

      case AppConstants.nextInspection:
        filtered.sort((a, b) {
          final aDateStr = a.stop?.timeSlot;
          final bDateStr = b.stop?.timeSlot;

          // Handle nulls - branches without scheduled inspections go to the end
          if (aDateStr == null && bDateStr == null) return 0;
          if (aDateStr == null) return 1;
          if (bDateStr == null) return -1;

          try {
            final aDate = DateTime.parse(aDateStr);
            final bDate = DateTime.parse(bDateStr);
            // Sort by earliest date first
            final comparison = aDate.compareTo(bDate);
            if (comparison != 0) return comparison;
            // If dates are equal, sort by name
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          } catch (_) {
            // If parsing fails, keep the same order
            return 0;
          }
        });
        break;

      case AppConstants.lastInspection:
        filtered.sort((a, b) {
          // Handle nulls - branches never inspected go to the end
          if (a.lastInspectionDate == null && b.lastInspectionDate == null)
            return 0;
          if (a.lastInspectionDate == null) return 1;
          if (b.lastInspectionDate == null) return -1;

          // Sort by most recent first
          final comparison = b.lastInspectionDate!.compareTo(
            a.lastInspectionDate!,
          );
          if (comparison != 0) return comparison;
          // If dates are equal, sort by name
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;

      case AppConstants.region:
        filtered.sort((a, b) {
          final aRegion = a.region ?? '';
          final bRegion = b.region ?? '';

          // Handle nulls - branches without region go to the end
          if (aRegion.isEmpty && bRegion.isEmpty) return 0;
          if (aRegion.isEmpty) return 1;
          if (bRegion.isEmpty) return -1;

          // Sort by region alphabetically
          final comparison = aRegion.toLowerCase().compareTo(
            bRegion.toLowerCase(),
          );
          if (comparison != 0) return comparison;
          // If regions are equal, sort by name
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;

      case AppConstants.inspector:
        filtered.sort((a, b) {
          final aInspector = a.assignedInspector?.name ?? '';
          final bInspector = b.assignedInspector?.name ?? '';

          // Handle nulls - branches without assigned inspector go to the end
          if (aInspector.isEmpty && bInspector.isEmpty) return 0;
          if (aInspector.isEmpty) return 1;
          if (bInspector.isEmpty) return -1;

          // Sort by inspector name alphabetically
          final comparison = aInspector.toLowerCase().compareTo(
            bInspector.toLowerCase(),
          );
          if (comparison != 0) return comparison;
          // If inspectors are equal, sort by branch name
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;

      default:
        // Default to name sorting
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }

    return filtered;
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
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
      await _branchService.updateBranchTemplate(
        branchId: branchId,
        templateId: templateId,
        templateName: templateName,
      );
      return true;
    } catch (e) {
      console('❌ Error updating template: $e');
      return false;
    } finally {}
  }

  Future<bool> addBranch({required BranchModel branch}) async {
    try {
      console('Adding Branch...');
      await _branchService.addBranch(branch);
      return true;
    } catch (e) {
      console('❌ Error updating template: $e');
      return false;
    } finally {}
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
      console('Unassigning branch from ${inspectorId} ${branchId}...');

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
