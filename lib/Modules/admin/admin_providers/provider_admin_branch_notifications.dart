import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import '../../../models/branch_notification_model.dart';
import '../admin_firebase_services/admin_branch_notification_service.dart';

class AdminBranchNotificationsProvider extends ChangeNotifier {
  final AdminBranchNotificationService _service =
      AdminBranchNotificationService();

  List<BranchNotificationModel> _notifications = [];
  List<BranchNotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _currentBranchId;
  String? get currentBranchId => _currentBranchId;

  // Search and filter state
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedFilter = 'All'; // All, Unread, Read
  String get selectedFilter => _selectedFilter;

  // Stream subscription for real-time updates
  Stream<QuerySnapshot>? _notificationsStream;

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Update selected filter
  void updateFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Get filtered notifications based on search and filter
  List<BranchNotificationModel> getFilteredNotifications() {
    var filtered = _notifications;

    // Apply search filter
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (n) =>
                n.title.toLowerCase().contains(query) ||
                n.description.toLowerCase().contains(query),
          )
          .toList();
    }

    // Apply status filter
    if (_selectedFilter == 'Unread') {
      filtered = filtered.where((n) => !n.isSeen).toList();
    } else if (_selectedFilter == 'Read') {
      filtered = filtered.where((n) => n.isSeen).toList();
    }

    return filtered;
  }

  /// Load notifications for a specific branch
  void loadNotificationsForBranch(String branchId) {
    _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notificationsStream = _service.getNotificationsForBranch(branchId);
      _notificationsStream!.listen(
        (snapshot) {
          _notifications = snapshot.docs
              .map((doc) => BranchNotificationModel.fromFirestore(doc))
              .toList();
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new notification
  Future<bool> createNotification({
    required String title,
    required String description,
    required String branchId,
    required String branchName,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.createNotification(
        title: title,
        description: description,
        branchId: branchId,
        branchName: branchName,
      );

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, "Notification created successfully");
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, 'Error creating notification: $e');
      }
      return false;
    }
  }

  /// Update an existing notification
  Future<bool> updateNotification({
    required String notificationId,
    required String title,
    required String description,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.updateNotification(
        notificationId: notificationId,
        title: title,
        description: description,
      );

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, "Notification updated successfully");
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, 'Error updating notification: $e');
      }
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(
    String notificationId, {
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.deleteNotification(notificationId);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, "Notification deleted successfully");
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, 'Error deleting notification: $e');
      }
      return false;
    }
  }

  /// Get the count of currently loaded notifications
  int getLoadedNotificationCount() => _notifications.length;

  /// Get count of unseen notifications for the current branch
  int getUnseenCount() => _notifications.where((n) => !n.isSeen).length;

  /// Clear all data and reset the provider
  void clear() {
    _notifications = [];
    _errorMessage = null;
    _isLoading = false;
    _currentBranchId = null;
    _notificationsStream = null;
    _searchQuery = '';
    _selectedFilter = 'All';
    notifyListeners();
  }
}
