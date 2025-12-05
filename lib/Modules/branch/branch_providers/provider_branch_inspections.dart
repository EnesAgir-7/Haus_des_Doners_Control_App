import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/inspection_model.dart';
import '../firebase_services/branch_inspection_service.dart';

class ProviderBranchInspections extends ChangeNotifier {
  final BranchInspectionService _inspectionService = BranchInspectionService();

  // State
  List<InspectionModel> _inspections = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  Timer? _debounce;
  String? _activeBranchId;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  // Filters and sorting
  String _searchQuery = '';
  String _sortBy = AppConstants.date;

  // Getters
  List<InspectionModel> get inspections => _inspections;
  int get pageNo => _currentPage;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  // Pagination helper
  DocumentSnapshot? _lastDocument;

  // Initialize
  Future<void> initialize({String? branchId}) async {
    if (_inspections.isNotEmpty && _activeBranchId == branchId) return;
    _activeBranchId = branchId;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fetchInspections(reset: true, branchId: branchId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch inspections from service
  Future<void> _fetchInspections({bool reset = false, String? branchId}) async {
    if (reset) {
      _currentPage = 0;
      _inspections = [];
      _lastDocument = null;
      _hasMore = true;
    }

    try {
      final response = await _inspectionService.getInspections(
        pageSize: _pageSize,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        lastDocument: _lastDocument,
        branchId: branchId,
      );

      final List<InspectionModel> newInspections =
          response[Collections.inspections] as List<InspectionModel>;

      _lastDocument = response['lastDocument'] as DocumentSnapshot?;
      _hasMore = response['hasMore'] as bool;

      _inspections.addAll(newInspections);
      _currentPage++;
      _errorMessage = null;
    } catch (e) {
      _errorMessage =
          '${LocaleKeys.failed_to_load_inspections.tr()}: ${e.toString()}';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Load more inspections (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _fetchInspections(branchId: _activeBranchId);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Refresh inspections
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fetchInspections(reset: true, branchId: _activeBranchId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () {
      refresh();
    });
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) return;
    _sortBy = sortBy;

    _sortLocally(); // Sort existing items without new Firestore query
    notifyListeners();
  }

  // Sort locally based on the current sortBy
  void _sortLocally() {
    switch (_sortBy) {
      case AppConstants.date:
        _inspections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case AppConstants.branch:
        _inspections.sort((a, b) => a.branchName.compareTo(b.branchName));
        break;
      case AppConstants.score:
        _inspections.sort((a, b) => b.score.compareTo(a.score));
        break;
      default:
        break;
    }
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _sortBy = AppConstants.date;
    refresh();
  }
}
