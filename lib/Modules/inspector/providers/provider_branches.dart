// lib/providers/subsidiaries_provider.dart
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';

import '../../../core/console.dart';
import '../../../core/constants/app_constants.dart';
import '../firebase_services/inspector_branch_service.dart';
import '../firebase_services/inspector_inspection_service.dart';
import '../../../models/branch_model.dart';
import '../../../models/inspection_model.dart';

/// Provider for Subsidiaries (Branches) screen
/// Shows list of branches assigned to inspector
class ProviderBranches extends ChangeNotifier {
  final InspectorBranchService _branchService = InspectorBranchService();
  final InspectorInspectionService _inspectionService =
      InspectorInspectionService();

  // Stream Subscriptions
  StreamSubscription<List<BranchModel>>? _branchesSubscription;
  StreamSubscription<List<InspectionModel>>? _inspectionsSubscription;

  // State
  List<BranchModel> _branches = [];
  BranchModel? _selectedBranch;
  List<InspectionModel> _branchInspections = [];
  bool _isLoading = false;
  bool _isLoadingInspections = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _sortBy = AppConstants.name; // name, score, lastInspection

  // Getters
  List<BranchModel> get branches => _filteredAndSortedBranches();
  BranchModel? get selectedBranch => _selectedBranch;
  List<InspectionModel> get branchInspections => _branchInspections;
  bool get isLoading => _isLoading;
  bool get isLoadingInspections => _isLoadingInspections;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  int get branchCount => _branches.length;
  String? _currentInspectorId;

  // Initialize
  Future<void> initialize() async {
    // await fetchBranches();
    await initializeWithStreams();
  }

  // Stream-based initialization (real-time updates)
  // 🔥 Real-time stream initialization (for branches)
  initializeWithStreams() {
    if (_branchesSubscription != null &&
        _currentInspectorId == loggedInUser!.id) {
      console("Same user and stream is On");
      return;
    }
    _branchesSubscription?.cancel();
    _currentInspectorId = loggedInUser!.id;

    _branchesSubscription = _branchService
        .streamBranchesByInspector(loggedInUser!.id)
        .listen(
          (branches) {
            _branches = branches;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Stream error: $error';
            notifyListeners();
          },
        );
  }

  // Select a branch and stream its inspections in real-time
  Future<void> selectBranch(BranchModel branch) async {
    if (_selectedBranch?.id == branch.id && _inspectionsSubscription != null) {
      console("Same user and stream is On");
      return;
    }
    _selectedBranch = branch;
    notifyListeners();

    _inspectionsSubscription?.cancel();

    _inspectionsSubscription = _inspectionService
        .streamInspectionsByBranch(branch.id)
        .listen(
          (inspections) {
            _branchInspections = inspections;
            _isLoadingInspections = false;
            notifyListeners();
          },
          onError: (error) {
            print('Inspection stream error: $error');
            _isLoadingInspections = false;
            notifyListeners();
          },
        );

    _isLoadingInspections = true;
    notifyListeners();
  }

  // Clear selected branch
  void clearSelection() {
    _selectedBranch = null;
    _branchInspections = [];
    notifyListeners();
  }

  // Search and filter
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  List<BranchModel> _filteredAndSortedBranches() {
    var filtered = _branches;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((branch) {
        return branch.name.toLowerCase().contains(_searchQuery) ||
            branch.address.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case AppConstants.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case AppConstants.nextInspection:
        filtered.sort((a, b) {
          final aDateStr = a.stop?.timeSlot;
          final bDateStr = b.stop?.timeSlot;

          // Handle nulls first
          if (aDateStr == null && bDateStr == null) return 0;
          if (aDateStr == null) return 1; // put nulls at bottom
          if (bDateStr == null) return -1;

          try {
            final aDate = DateTime.parse(aDateStr);
            final bDate = DateTime.parse(bDateStr);
            return aDate.compareTo(bDate); // earliest first
          } catch (_) {
            // If parsing fails, keep the same order
            return 0;
          }
        });

        break;
      case AppConstants.score:
        filtered.sort((a, b) => b.averageScore.compareTo(a.averageScore));
        break;
      case AppConstants.lastInspection:
        filtered.sort((a, b) {
          if (a.lastInspectionDate == null) return 1;
          if (b.lastInspectionDate == null) return -1;
          return b.lastInspectionDate!.compareTo(a.lastInspectionDate!);
        });
        break;
    }

    return filtered;
  }

  Future<bool> updateStopTimeSlotForMe({
    required String branchId,
    required String newTimeSlot,
    required int order,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _branchService.updateStopTimeSlot(
        inspectorId: loggedInUser!.id,
        branchId: branchId,
        newTimeSlot: newTimeSlot,
        order: order,
      );

      _isLoading = false;
      notifyListeners();
      showSnakBarr(context, "Stop time slot updated successfully");
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showSnakBarr(context, "Failed to update stop time slot: $e");
      return false;
    }
  }

  Future<bool> assignBranchToMe({
    required String branchId,
    required String branchName,
    required String branchAddress,
    required String timeSlot,
    required String branchTemplateId,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _branchService.assignBranchToHimself(
        inspectorId: loggedInUser!.id,
        inspectorName: loggedInUser!.name,
        timeSlot: timeSlot,
        branchId: branchId,
        branchName: branchName,
        branchTemplateId: branchTemplateId,
        branchAddress: branchAddress,
      );

      _isLoading = false;
      notifyListeners();
      showSnakBarr(context, LocaleKeys.branch_assigned_successfully.tr());
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showCustomSnackBar(context, "Failed to assign branch: $e");
      return false;
    }
  }

  Future<bool> unAssignMyRoute({
    required String branchId,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _branchService.unAssignRouteAndFreeTheBranch(
        inspectorId: loggedInUser!.id,
        branchId: branchId,
      );

      _isLoading = false;
      notifyListeners();
      showSnakBarr(context, LocaleKeys.branch_unassigned_successfully.tr());
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showSnakBarr(context, "Failed to unassign branch: $e");
      return false;
    }
  }

  // Refresh
  Future<void> refresh() async {
    initializeWithStreams();
    // await fetchBranches();
    // if (_selectedBranch != null) {
    //   await fetchLastTenBranchInspections(_selectedBranch!.id);
    // }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _branchesSubscription?.cancel();
    _inspectionsSubscription?.cancel();
    super.dispose();
  }
}
