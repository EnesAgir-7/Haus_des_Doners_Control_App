// lib/providers/subsidiaries_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/widgets/custom_toast.dart';

import '../firebase_services/firebase_branch_service.dart';
import '../firebase_services/firebase_inspection_service.dart';
import '../models/branch_model.dart';
import '../models/inspection_model.dart';

/// Provider for Subsidiaries (Branches) screen
/// Shows list of branches assigned to inspector
class ProviderBranches extends ChangeNotifier {
  final BranchService _branchService = BranchService();
  final InspectionService _inspectionService = InspectionService();

  // State
  List<BranchModel> _branches = [];
  BranchModel? _selectedBranch;
  List<InspectionModel> _branchInspections = [];
  bool _isLoading = false;
  bool _isLoadingInspections = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _sortBy = 'name'; // name, score, lastInspection

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

  // Initialize
  Future<void> initialize() async {
    await fetchBranches();
  }

  // Fetch branches assigned to inspector
  Future<void> fetchBranches() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _branches = await _branchService.getBranchesByInspector(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading branches: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_errorMessage);
    }
  }

  // Stream-based initialization (real-time updates)
  void initializeWithStreams() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _branchService.streamBranchesByInspector(userId).listen((branches) {
      _branches = branches;
      notifyListeners();
    });
  }

  // Select a branch and load its inspection history
  Future<void> selectBranch(BranchModel branch) async {
    _selectedBranch = branch;
    notifyListeners();
    await fetchBranchInspections(branch.id);
  }

  // Fetch inspections for selected branch
  Future<void> fetchBranchInspections(String branchId) async {
    try {
      _isLoadingInspections = true;
      notifyListeners();

      _branchInspections = await _inspectionService.getInspectionsByBranch(
        branchId,
      );

      _isLoadingInspections = false;
      notifyListeners();
    } catch (e) {
      print('Error loading branch inspections: ${e.toString()}');
      _isLoadingInspections = false;
      notifyListeners();
    }
  }

  // Stream inspections for selected branch (real-time)
  void streamBranchInspections(String branchId) {
    _inspectionService.streamInspectionsByBranch(branchId).listen((
      inspections,
    ) {
      _branchInspections = inspections;
      notifyListeners();
    });
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
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'score':
        filtered.sort((a, b) => b.averageScore.compareTo(a.averageScore));
        break;
      case 'lastInspection':
        filtered.sort((a, b) {
          if (a.lastInspectionDate == null) return 1;
          if (b.lastInspectionDate == null) return -1;
          return b.lastInspectionDate!.compareTo(a.lastInspectionDate!);
        });
        break;
    }

    return filtered;
  }

  Future<void> assignBranchToMe({
    required String branchId,
    required String branchName,
    required String timeSlot,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      await _branchService.assignBranchToHimself(
        inspectorId: userId!,
        inspectorName: 'You',
        branchId: branchId,
        branchName: branchName,
        timeSlot: timeSlot,
      );

      _isLoading = false;
      notifyListeners();

      showSnakBarr(context, "Branch assigned successfully");
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showSnakBarr(context, "Failed to assign branch");
    }
  }

  Future<void> unAssignBranchToMe({
    required String branchId,
    required BuildContext context, 
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      await _branchService.removeBranchAssignment(
        inspectorId: userId!,
        branchId: branchId,
      );

      _isLoading = false;
      notifyListeners();

      showSnakBarr(context, "Branch assigned successfully");
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showSnakBarr(context, "Failed to assign branch");
    }
  }

  // Refresh
  Future<void> refresh() async {
    await fetchBranches();
    if (_selectedBranch != null) {
      await fetchBranchInspections(_selectedBranch!.id);
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
