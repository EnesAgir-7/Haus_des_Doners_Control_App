import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/branch_notification_model.dart';
import '../firebase_services/branch_notification_service.dart';

class BranchNotificationsProvider extends ChangeNotifier {
  final BranchNotificationService _service = BranchNotificationService();

  List<BranchNotificationModel> _notifications = [];
  List<BranchNotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _unseenCount = 0;
  int get unseenCount => _unseenCount;

  String? currentBranchId;

  // Stream subscription for real-time updates
  Stream<QuerySnapshot>? _notificationsStream;

  /// Load notifications for the current branch
  void loadNotificationsForBranch(String branchId) {
    currentBranchId = branchId;
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
          _unseenCount = _notifications.where((n) => !n.isSeen).length;
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

  /// Mark a notification as seen
  Future<void> markAsSeen(String notificationId) async {
    try {
      await _service.markNotificationAsSeen(notificationId);
      // The listener will automatically update the list
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Get count of unseen notifications
  int getUnseenCount() => _unseenCount;

  /// Clear all data and reset the provider
  void clear() {
    _notifications = [];
    _errorMessage = null;
    _isLoading = false;
    _unseenCount = 0;
    currentBranchId = null;
    _notificationsStream = null;
    notifyListeners();
  }
}
