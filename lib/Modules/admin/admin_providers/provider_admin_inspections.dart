import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/inspection_model.dart';
import '../admin_firebase_services/admin_inspection_service.dart';

class ProviderAdminInspections extends ChangeNotifier {
  final AdminInspectionService _inspectionService = AdminInspectionService();

  // State
  List<InspectionModel> _inspections = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  Timer? _debounce;

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
  Future<void> initialize() async {
    if (_inspections.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fetchInspections(reset: true);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch inspections from service
  Future<void> _fetchInspections({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _inspections = [];
      _lastDocument = null;
      _hasMore = true;
    }

    try {
      final response = await _inspectionService.getInspections(
        pageSize: _pageSize,
        sortBy: _sortBy,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        lastDocument: _lastDocument,
      );

      final List<InspectionModel> newInspections =
          response['inspections'] as List<InspectionModel>;

      _lastDocument = response['lastDocument'] as DocumentSnapshot?;
      _hasMore = response['hasMore'] as bool;

      _inspections.addAll(newInspections);
      _currentPage++;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to load inspections: ${e.toString()}";
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
      await _fetchInspections();
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
      await _fetchInspections(reset: true);
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
    refresh();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _sortBy = AppConstants.date;
    refresh();
  }
}
