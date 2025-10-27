// lib/providers/tasks_provider.dart
import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../core/console.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/task_model.dart';
import '../firebase_services/inspector_tasks_service.dart';

/// Provider for Tasks screen
/// Shows and manages tasks assigned to inspector
class ProviderTasks extends ChangeNotifier {
  final InspectorTaskService _taskService = InspectorTaskService();

  // State
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  bool _isAddingComment = false;

  // Filters
  String _statusFilter = AppConstants.all;
  String _priorityFilter = AppConstants.all;
  String _sortBy = AppConstants.dueDate;

  // Comment input
  final TextEditingController commentController = TextEditingController();
  List<File> _commentPhotos = [];

  // Getters
  List<TaskModel> get tasks => _filteredAndSortedTasks();
  bool get isLoading => _isLoading;
  bool get isAddingComment => _isAddingComment;
  String get statusFilter => _statusFilter;

  // Computed values
  int get totalTasks => _tasks.length;
  int get pendingTasksCount => _tasks.where((t) => t.isPending).length;
  int get inProgressTasksCount => _tasks.where((t) => t.isInProgress).length;
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get overdueTasksCount => _tasks.where((t) => t.isOverdue).length;

  StreamSubscription<List<TaskModel>>? _tasksSubscription;
  String? _currentInspectorId;
  Future<void> initialize() async {
    initializeTasksStream();
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
      _tasksSubscription = _taskService
          .streamTasksByInspector(inspectorId)
          .listen(
            (tasks) {
              _tasks = tasks;
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

  // Filter and sort tasks
  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  List<TaskModel> _filteredAndSortedTasks() {
    var filtered = _tasks;

    // Filter by status
    if (_statusFilter != AppConstants.all) {
      filtered = filtered
          .where((task) => task.status == _statusFilter)
          .toList();
    }

    // Filter by priority
    if (_priorityFilter != AppConstants.all) {
      filtered = filtered
          .where((task) => task.priority == _priorityFilter)
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case AppConstants.dueDate:
        filtered.sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case AppConstants.priority:
        final priorityOrder = {
          AppConstants.high: 0,
          AppConstants.medium: 1,
          AppConstants.low: 2,
        };
        filtered.sort(
          (a, b) =>
              priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!),
        );
        break;
      case AppConstants.createdAt:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  // Update task status
  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _taskService.updateTaskStatus(taskId, newStatus);

      notifyListeners();

      // Update local state
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = TaskModel(
          id: _tasks[index].id,
          title: _tasks[index].title,
          description: _tasks[index].description,
          assignedInspectorId: _tasks[index].assignedInspectorId,
          assignedInspectorName: _tasks[index].assignedInspectorName,
          relatedBranchId: _tasks[index].relatedBranchId,
          relatedInspectionId: _tasks[index].relatedInspectionId,
          status: newStatus,
          priority: _tasks[index].priority,
          dueDate: _tasks[index].dueDate,
          comments: _tasks[index].comments,
          createdAt: _tasks[index].createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
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
  ) async {
    final commentText = commentController.text.trim();

    if (commentText.isEmpty && _commentPhotos.isEmpty) {
      showSnakBarr(context, 'Please add a comment or photo');
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
        userName: loggedInUser?.name ?? 'Inspector',
        text: commentText,
        timestamp: DateTime.now(),
        photos: photoUrls,
      );

      // Save comment in backend
      await _taskService.addTaskComment(taskId, comment);

      _isAddingComment = false;
      notifyListeners();

      commentController.clear();
      _commentPhotos.clear();

      notifyListeners();

      // ✅ Return the created comment so the UI can append it locally
      return comment;
    } catch (e) {
      showSnakBarr(context, 'Failed to add comment: $e');
      _isAddingComment = false;
      notifyListeners();
      return null;
    }
  }

  // Helper methods for status
  Future<bool> markAsPending(String taskId) async =>
      await updateTaskStatus(taskId, AppConstants.pending);

  Future<bool> markAsInProgress(String taskId) async =>
      await updateTaskStatus(taskId, AppConstants.inProgress);

  Future<bool> markAsCompleted(String taskId) async =>
      await updateTaskStatus(taskId, AppConstants.completed);

  // Utility methods
  TaskModel? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }

  List<TaskModel> getTasksByBranch(String branchId) {
    return _tasks.where((t) => t.relatedBranchId == branchId).toList();
  }

  Future<void> refresh() async {
    initializeTasksStream();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    commentController.dispose();
    super.dispose();
  }
}
