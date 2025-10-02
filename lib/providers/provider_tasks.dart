// lib/providers/tasks_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../firebase_services/firebase_tasks_service.dart';
import '../models/task_model.dart';

/// Provider for Tasks screen
/// Shows and manages tasks assigned to inspector
class ProviderTasks extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  // State
  List<TaskModel> _tasks = [];
  TaskModel? _selectedTask;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isAddingComment = false;
  String? _errorMessage;
  String? _successMessage;

  // Filters
  String _statusFilter = 'all'; // all, pending, in_progress, completed
  String _priorityFilter = 'all'; // all, low, medium, high
  String _sortBy = 'dueDate'; // dueDate, priority, createdAt

  // Comment input
  final TextEditingController commentController = TextEditingController();
  List<File> _commentPhotos = [];

  // Getters
  List<TaskModel> get tasks => _filteredAndSortedTasks();
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

  // Computed values
  int get totalTasks => _tasks.length;
  int get pendingTasksCount => _tasks.where((t) => t.isPending).length;
  int get inProgressTasksCount => _tasks.where((t) => t.isInProgress).length;
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get overdueTasksCount => _tasks.where((t) => t.isOverdue).length;

  List<TaskModel> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();

  List<TaskModel> get highPriorityTasks =>
      _tasks.where((t) => t.priority == 'high' && !t.isCompleted).toList();

  // Initialize
  Future<void> initialize() async {
    await fetchTasks();
  }

  // Fetch tasks for current inspector
  Future<void> fetchTasks() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _tasks = await _taskService.getTasksByInspector(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading tasks: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_errorMessage);
    }
  }

  // Stream-based initialization (real-time updates)
  void initializeWithStreams() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _taskService.streamTasksByInspector(userId).listen((tasks) {
      _tasks = tasks;
      notifyListeners();
    });
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

  List<TaskModel> _filteredAndSortedTasks() {
    var filtered = _tasks;

    // Filter by status
    if (_statusFilter != 'all') {
      filtered = filtered
          .where((task) => task.status == _statusFilter)
          .toList();
    }

    // Filter by priority
    if (_priorityFilter != 'all') {
      filtered = filtered
          .where((task) => task.priority == _priorityFilter)
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'dueDate':
        filtered.sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'priority':
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        filtered.sort(
          (a, b) =>
              priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!),
        );
        break;
      case 'createdAt':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  // Update task status
  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    try {
      _isUpdating = true;
      _errorMessage = null;
      notifyListeners();

      await _taskService.updateTaskStatus(taskId, newStatus);

      _successMessage = 'Görev durumu güncellendi';
      _isUpdating = false;
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

      // Clear success message after 2 seconds
      await Future.delayed(Duration(seconds: 2));
      _successMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage =
          'Görev durumu güncellenirken hata oluştu: ${e.toString()}';
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
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading comment photo: $e');
      rethrow;
    }
  }

  // Add comment to task
  Future<bool> addComment(String taskId) async {
    final commentText = commentController.text.trim();
    if (commentText.isEmpty && _commentPhotos.isEmpty) {
      _errorMessage = 'Lütfen yorum veya fotoğraf ekleyin';
      notifyListeners();
      return false;
    }

    try {
      _isAddingComment = true;
      _errorMessage = null;
      notifyListeners();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Upload photos
      final photoUrls = <String>[];
      for (final photo in _commentPhotos) {
        final url = await _uploadCommentPhoto(photo, taskId);
        photoUrls.add(url);
      }

      // Create comment
      final comment = TaskCommentModel(
        userId: userId,
        userName: FirebaseAuth.instance.currentUser?.displayName ?? 'Inspector',
        text: commentText,
        timestamp: DateTime.now(),
        photos: photoUrls,
      );

      await _taskService.addTaskComment(taskId, comment);

      _successMessage = 'Yorum eklendi';
      _isAddingComment = false;
      notifyListeners();

      // Clear input
      commentController.clear();
      _commentPhotos.clear();

      // Refresh tasks
      await fetchTasks();

      // Clear success message
      await Future.delayed(Duration(seconds: 2));
      _successMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Yorum eklenirken hata oluştu: ${e.toString()}';
      _isAddingComment = false;
      notifyListeners();
      return false;
    }
  }

  // Mark task as pending
  Future<bool> markAsPending(String taskId) async {
    return await updateTaskStatus(taskId, 'pending');
  }

  // Mark task as in progress
  Future<bool> markAsInProgress(String taskId) async {
    return await updateTaskStatus(taskId, 'in_progress');
  }

  // Mark task as completed
  Future<bool> markAsCompleted(String taskId) async {
    return await updateTaskStatus(taskId, 'completed');
  }

  // Get task by ID
  TaskModel? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // Get tasks by related branch
  List<TaskModel> getTasksByBranch(String branchId) {
    return _tasks.where((t) => t.relatedBranchId == branchId).toList();
  }

  // Refresh
  Future<void> refresh() async {
    await fetchTasks();
  }

  // Clear messages
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
    commentController.dispose();
    super.dispose();
  }
}
