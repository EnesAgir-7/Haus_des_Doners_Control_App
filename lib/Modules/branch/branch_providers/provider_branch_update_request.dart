import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import '../../../models/branch_update_request_model.dart';
import '../../../models/branch_model.dart';
import '../firebase_services/branch_update_request_service.dart';

class BranchUpdateRequestProvider extends ChangeNotifier {
  final BranchUpdateRequestService _service = BranchUpdateRequestService();

  // Pending request
  BranchUpdateRequestModel? _pendingRequest;
  BranchUpdateRequestModel? get pendingRequest => _pendingRequest;

  // Request history
  List<BranchUpdateRequestModel> _requestHistory = [];
  List<BranchUpdateRequestModel> get requestHistory => _requestHistory;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  // Error handling
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Current branch tracking
  String? _currentBranchId;
  String? get currentBranchId => _currentBranchId;

  // Check if branch has pending request
  Future<bool> checkPendingRequest(String branchId) async {
    _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingRequest = await _service.getPendingRequest(branchId);
      return _pendingRequest != null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error checking pending request: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit update request
  Future<bool> submitUpdateRequest({
    required BranchModel oldBranch,
    required BranchModel newBranch,
    required String requestedBy,
    required String requestedByName,
    required BuildContext context,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Compare and extract changes
      final changes = _service.compareAndExtractChanges(oldBranch, newBranch);

      // Check if there are any changes
      if (changes.isEmpty) {
        throw Exception(
          'No changes detected. Please modify at least one field.',
        );
      }

      // Check if already has pending request
      final hasPending = await _service.hasPendingRequest(oldBranch.id);
      if (hasPending) {
        throw Exception(
          'You already have a pending update request. '
          'Please wait for admin approval or delete the existing request.',
        );
      }

      // Create request
      final requestId = await _service.createUpdateRequest(
        branchId: oldBranch.id,
        branchName: oldBranch.name,
        requestedBy: requestedBy,
        requestedByName: requestedByName,
        changes: changes,
      );

      debugPrint('Update request created with ID: $requestId');

      // Refresh pending request to show banner
      await checkPendingRequest(oldBranch.id);

      if (context.mounted) {
        showSnakBarr(
          context,
          'Update request submitted successfully! (${changes.length} ${changes.length == 1 ? 'change' : 'changes'})',
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error submitting update request: $e');

      if (context.mounted) {
        showSnakBarr(context, _errorMessage!);
      }
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Delete pending request
  Future<bool> deletePendingRequest(BuildContext context) async {
    if (_pendingRequest == null) {
      if (context.mounted) {
        showSnakBarr(context, 'No pending request to delete');
      }
      return false;
    }

    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteRequest(_pendingRequest!.id);

      // Clear pending request
      final deletedId = _pendingRequest!.id;
      _pendingRequest = null;

      debugPrint('Request deleted: $deletedId');

      if (context.mounted) {
        showSnakBarr(context, "Request deleted successfully");
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting request: $e');

      if (context.mounted) {
        showSnakBarr(context, 'Error deleting request: ${e.toString()}');
      }
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // Load request history (all requests for branch)
  Future<void> loadRequestHistory(String branchId, {String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _requestHistory = await _service.getBranchRequests(
        branchId,
        status: status,
      );
      debugPrint('Loaded ${_requestHistory.length} requests from history');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading request history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh current state (pending request + history)
  Future<void> refresh(String branchId) async {
    await Future.wait([
      checkPendingRequest(branchId),
      loadRequestHistory(branchId),
    ]);
  }

  // Get specific request by ID
  BranchUpdateRequestModel? getRequestById(String requestId) {
    try {
      return _requestHistory.firstWhere((req) => req.id == requestId);
    } catch (e) {
      return null;
    }
  }

  // Filter history by status
  List<BranchUpdateRequestModel> getRequestsByStatus(String status) {
    return _requestHistory.where((req) => req.status == status).toList();
  }

  // Get approved requests
  List<BranchUpdateRequestModel> get approvedRequests {
    return _requestHistory.where((req) => req.isApproved).toList();
  }

  // Get rejected requests
  List<BranchUpdateRequestModel> get rejectedRequests {
    return _requestHistory.where((req) => req.isRejected).toList();
  }

  // Get pending requests from history (should only be one or zero)
  List<BranchUpdateRequestModel> get pendingRequests {
    return _requestHistory.where((req) => req.isPending).toList();
  }

  // Get total request count
  int get totalRequestCount => _requestHistory.length;

  // Get approved count
  int get approvedCount => approvedRequests.length;

  // Get rejected count
  int get rejectedCount => rejectedRequests.length;

  // Get pending count
  int get pendingCount => pendingRequests.length;

  // Get changes count from pending request
  int get pendingChangesCount => _pendingRequest?.changeCount ?? 0;

  // Check if has pending request
  bool get hasPendingRequest => _pendingRequest != null;

  // Get pending request status text
  String get pendingRequestStatusText {
    if (_pendingRequest == null) return 'No pending request';

    final changeCount = _pendingRequest!.changeCount;
    return 'Pending - $changeCount ${changeCount == 1 ? 'change' : 'changes'}';
  }

  // Get specific field change from pending request
  FieldChange? getFieldChange(String fieldKey) {
    return _pendingRequest?.changes[fieldKey];
  }

  // Get all field changes from pending request
  Map<String, FieldChange> get allChanges => _pendingRequest?.changes ?? {};

  // Check if specific field has changed
  bool hasFieldChanged(String fieldKey) {
    return _pendingRequest?.changes.containsKey(fieldKey) ?? false;
  }

  // Get formatted pending request date
  String get pendingRequestDate {
    if (_pendingRequest == null) return '';

    final date = _pendingRequest!.requestedAt;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0)
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours > 0)
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inMinutes > 0)
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    return 'Just now';
  }

  // Check if any operation is in progress
  bool get isAnyOperationInProgress =>
      _isLoading || _isSubmitting || _isDeleting;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear pending request only
  void clearPendingRequest() {
    _pendingRequest = null;
    notifyListeners();
  }

  // Clear history only
  void clearHistory() {
    _requestHistory = [];
    notifyListeners();
  }

  // Clear everything and reset
  void clear() {
    _pendingRequest = null;
    _requestHistory = [];
    _currentBranchId = null;
    _errorMessage = null;
    _isLoading = false;
    _isSubmitting = false;
    _isDeleting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
