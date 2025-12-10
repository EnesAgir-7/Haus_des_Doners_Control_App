import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import '../../../models/branch_update_request_model.dart';
import '../admin_firebase_services/admin_update_requests_service.dart';

//TODO: locale
class AdminUpdateRequestProvider extends ChangeNotifier {
  final AdminUpdateRequestService _service = AdminUpdateRequestService();

  List<BranchUpdateRequestModel> _pendingRequests = [];
  List<BranchUpdateRequestModel> get pendingRequests => _pendingRequests;

  List<BranchUpdateRequestModel> _allRequests = [];
  List<BranchUpdateRequestModel> get allRequests => _allRequests;

  BranchUpdateRequestModel? _selectedRequest;
  BranchUpdateRequestModel? get selectedRequest => _selectedRequest;

  Map<String, int> _stats = {'pending': 0, 'approved': 0, 'rejected': 0};
  Map<String, int> get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isApproving = false;
  bool get isApproving => _isApproving;

  bool _isRejecting = false;
  bool get isRejecting => _isRejecting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _selectedFilter = 'pending';
  String get selectedFilter => _selectedFilter;

  // Load pending requests
  Future<void> loadPendingRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingRequests = await _service.getPendingRequests();
      debugPrint('Loaded ${_pendingRequests.length} pending requests');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading pending requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all requests with optional filter
  Future<void> loadAllRequests({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allRequests = await _service.getAllRequests(status: status);
      debugPrint('Loaded ${_allRequests.length} requests');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading all requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load statistics
  Future<void> loadStats() async {
    try {
      _stats = await _service.getRequestStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  // Select a request for viewing details
  void selectRequest(BranchUpdateRequestModel request) {
    _selectedRequest = request;
    notifyListeners();
  }

  // Clear selected request
  void clearSelection() {
    _selectedRequest = null;
    notifyListeners();
  }

  // Approve request
  Future<bool> approveRequest({
    required String requestId,
    required String branchId,
    required Map<String, FieldChange> changes,
    String? adminNote,
    required String adminId,
    required BuildContext context,
  }) async {
    _isApproving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.approveRequest(
        requestId,
        branchId: branchId,
        changes: changes,
        adminNote: adminNote,
        adminId: adminId,
      );

      // Remove from pending list
      _pendingRequests.removeWhere((req) => req.id == requestId);
      _allRequests.removeWhere((req) => req.id == requestId);

      // Clear selection
      if (_selectedRequest?.id == requestId) {
        _selectedRequest = null;
      }

      // Reload stats
      await loadStats();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved and branch updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error approving request: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      _isApproving = false;
      notifyListeners();
    }
  }

  // Reject request
  Future<bool> rejectRequest({
    required String requestId,
    required String adminNote,
    required String adminId,
    required BuildContext context,
  }) async {
    _isRejecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.rejectRequest(
        requestId,
        adminNote: adminNote,
        adminId: adminId,
      );

      // Remove from pending list
      _pendingRequests.removeWhere((req) => req.id == requestId);
      _allRequests.removeWhere((req) => req.id == requestId);

      // Clear selection
      if (_selectedRequest?.id == requestId) {
        _selectedRequest = null;
      }

      // Reload stats
      await loadStats();

      if (context.mounted) {
        showSnakBarr(context, 'Request rejected successfully');
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error rejecting request: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      _isRejecting = false;
      notifyListeners();
    }
  }

  // Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();

    // Load requests based on filter
    if (filter == 'all') {
      loadAllRequests();
    } else {
      loadAllRequests(status: filter);
    }
  }

  // Get filtered requests
  List<BranchUpdateRequestModel> get filteredRequests {
    if (_selectedFilter == 'pending') {
      return _pendingRequests;
    }
    return _allRequests;
  }

  // Get pending count
  int get pendingCount => _stats['pending'] ?? 0;

  // Get approved count
  int get approvedCount => _stats['approved'] ?? 0;

  // Get rejected count
  int get rejectedCount => _stats['rejected'] ?? 0;

  // Refresh all data
  Future<void> refresh() async {
    await Future.wait([loadPendingRequests(), loadStats()]);
  }

  // Check if any operation is in progress
  bool get isAnyOperationInProgress =>
      _isLoading || _isApproving || _isRejecting;

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _pendingRequests = [];
    _allRequests = [];
    _selectedRequest = null;
    _stats = {'pending': 0, 'approved': 0, 'rejected': 0};
    _errorMessage = null;
    _isLoading = false;
    _isApproving = false;
    _isRejecting = false;
    _selectedFilter = 'pending';
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
