import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import '../../../models/announcement_model.dart';
import '../admin_firebase_services/admin_announcement_service.dart';

class AdminAnnouncementsProvider extends ChangeNotifier {
  final AdminAnnouncementService _service = AdminAnnouncementService();

  List<AnnouncementModel> _announcements = [];
  List<AnnouncementModel> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Stream subscription for real-time updates
  Stream<QuerySnapshot>? _announcementsStream;

  void loadAllAnnouncements() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // This method returns ALL announcements - no branch filtering
      _announcementsStream = _service.getAllAnnouncements();
      _announcementsStream!.listen(
        (snapshot) {
          _announcements = snapshot.docs
              .map((doc) => AnnouncementModel.fromFirestore(doc))
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

  /// Create a new announcement
  Future<bool> createAnnouncement({
    required String title,
    required String description,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.createAnnouncement(title: title, description: description);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, "Announcement created successfully");
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, 'Error creating announcement: $e');
      }
      return false;
    }
  }

  /// Delete an announcement
  Future<bool> deleteAnnouncement(
    String announcementId, {
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.deleteAnnouncement(announcementId);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, "Announcement deleted successfully");
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnakBarr(context, 'Error deleting announcement: $e');
      }
      return false;
    }
  }

  /// Get the count of currently loaded announcements
  int getLoadedAnnouncementCount() => _announcements.length;

  /// Clear all data and reset the provider
  void clear() {
    _announcements = [];
    _errorMessage = null;
    _isLoading = false;
    _announcementsStream = null;
    notifyListeners();
  }
}
