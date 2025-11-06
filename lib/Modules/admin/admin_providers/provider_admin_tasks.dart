// lib/providers/tasks_provider.dart
import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../core/console.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/task_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../admin/admin_firebase_services/admin_tasks_service.dart';

/// Provider for Tasks screen
/// Shows and manages tasks assigned to inspector
class ProviderAdminTasks extends ChangeNotifier {
  final AdminTaskService _taskAdminService = AdminTaskService();

  List<TaskModel> _allTasks = []; // For admin view
  TaskModel? _selectedTask;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isAddingComment = false;
  String? _errorMessage;
  String? _successMessage;

  // Filters
  String _statusFilter = AppConstants.all;
  String _priorityFilter = AppConstants.all;
  String _sortBy = AppConstants.dueDate;

  // Comment input
  final TextEditingController commentController = TextEditingController();
  List<File> _commentPhotos = [];

  List<TaskModel> get allTasks => _allTasks;
  TaskModel? get selectedTask => _selectedTask;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isAddingComment => _isAddingComment;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get statusFilter => _statusFilter;
  String get priorityFilter => _priorityFilter;
  String get sortBy => _sortBy;
  List<File> get commentPhotos => _commentPhotos;

  StreamSubscription<List<TaskModel>>? _tasksSubscription;
  String? _currentInspectorId;

  Future<void> initialize() async {
    await initializeTasksStream();
  }

  initializeTasksStream() {
    final inspectorId = loggedInUser!.id;

    if (_tasksSubscription != null && _currentInspectorId == inspectorId) {
      console("Same user and stream is On");
      return;
    }
    _currentInspectorId = inspectorId;
    _tasksSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    try {
      _tasksSubscription = _taskAdminService
          .streamAllTasks(inspectorId)
          .listen(
            (tasks) {
              _allTasks = tasks;
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteComments(String taskId, List<String> commentIds) async {
    try {
      final success = await _taskAdminService.deleteComments(
        taskId,
        commentIds,
      );

      return success;
    } catch (e) {
      print('Provider error deleting comments: $e');
      return false;
    }
  }

  /// Delete a single comment from a task
  Future<bool> deleteComment(String taskId, String commentId) async {
    return deleteComments(taskId, [commentId]);
  }

  // Select a task
  void selectTask(TaskModel task) {
    _selectedTask = task;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedTask = null;
    commentController.clear();
    _commentPhotos.clear();
    notifyListeners();
  }

  // Filter and sort tasks
  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setPriorityFilter(String priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  // Update task status

  Future<bool> updateTask(
    String taskId,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    try {
      _isUpdating = true;
      _errorMessage = null;
      notifyListeners();

      // Service handles all batch operations and history updates
      await _taskAdminService.updateTask(taskId, data, context);

      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '${LocaleKeys.error_updating_task.tr()}: $e';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  // Add comment photos
  void addCommentPhoto(File photo) {
    if (_commentPhotos.length < 4) {
      _commentPhotos.add(photo);
      notifyListeners();
    }
  }

  void removeCommentPhoto(int index) {
    _commentPhotos.removeAt(index);
    notifyListeners();
  }

  // Upload comment photo to Firebase Storage
  Future<String> _uploadCommentPhoto(File photo, String taskId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'tasks/$taskId/comment_$timestamp.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final uploadTask = storageRef.putFile(photo);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading comment photo: $e');
      rethrow;
    }
  }

  // Add comment to task
  Future<TaskCommentModel?> addComment(
    String taskId,
    BuildContext context,
    String inspectorId, 
  ) async {
    final commentText = commentController.text.trim();

    if (commentText.isEmpty && _commentPhotos.isEmpty) {
      showSnakBarr(context, LocaleKeys.failed_to_add_comment.tr());
      return null;
    }

    try {
      _isAddingComment = true;
      notifyListeners();

      // Upload photos
      final photoUrls = <String>[];
      for (final photo in _commentPhotos) {
        final url = await _uploadCommentPhoto(photo, taskId);
        photoUrls.add(url);
      }

      // Generate unique ID for the comment
      final commentId =
          '${DateTime.now().millisecondsSinceEpoch}_${loggedInUser!.id}';

      // Create comment
      final comment = TaskCommentModel(
        id: commentId, // ✅ UPDATED: Use generated unique ID instead of taskId
        userId: loggedInUser!.id,
        userName: loggedInUser?.name ?? LocaleKeys.inspector.tr(),
        text: commentText,
        timestamp: DateTime.now(),
        photos: photoUrls,
      );

      // Save comment in backend
      await _taskAdminService.addTaskComment(taskId, comment, inspectorId );

      _isAddingComment = false;
      notifyListeners();

      commentController.clear();
      _commentPhotos.clear();

      notifyListeners();

      // ✅ Return the created comment so the UI can append it locally
      return comment;
    } catch (e) {
      showSnakBarr(context, '${LocaleKeys.failed_to_add_comment.tr()}: $e');
      _isAddingComment = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> createTask({
    required String title,
    required String description,
    required String assignedInspectorId,
    required String assignedInspectorName,
    String? relatedBranchId,
    String? relatedInspectionId,
    String status = AppConstants.pending,
    String priority = AppConstants.medium,
    DateTime? dueDate,
    required BuildContext context,
  }) async {
    try {
      _isUpdating = true;
      _errorMessage = null;
      notifyListeners();

      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: title,
        description: description,
        assignedInspectorId: assignedInspectorId,
        assignedInspectorName: assignedInspectorName,
        relatedBranchId: relatedBranchId,
        status: status,
        priority: priority,
        dueDate: dueDate,
        comments: [],
        createdAt: now,
        updatedAt: now,
      );

      // Service handles all batch operations and history updates
      await _taskAdminService.createTask(task, context);

      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '${LocaleKeys.error_creating_task.tr()}: $e';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId, BuildContext context) async {
    try {
      _isUpdating = true;
      notifyListeners();

      await _taskAdminService.deleteTask(taskId, context);

      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    commentController.dispose();
    super.dispose();
  }
}
