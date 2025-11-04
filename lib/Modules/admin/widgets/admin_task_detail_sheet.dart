// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/core/extensions.dart';
import 'package:haus_des_control/models/task_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../translations/locale_keys.g.dart';
import '../../inspector/screens/screen_full_image.dart';
import '../admin_providers/provider_admin_tasks.dart';
import 'task_add_edit_widget.dart';

class AdminTaskDetailSheet extends StatefulWidget {
  final TaskModel task;
  final VoidCallback? onTaskUpdated;

  const AdminTaskDetailSheet({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  @override
  State<AdminTaskDetailSheet> createState() => _AdminTaskDetailSheetState();
}

class _AdminTaskDetailSheetState extends State<AdminTaskDetailSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  List<File> _commentPhotos = [];
  bool _isAddingComment = false;
  bool _showCommentInput = false;
  late TaskModel _currentTask;

  // Selection mode
  bool _isSelectionMode = false;
  Set<int> _selectedCommentIndices = {};
  bool _isDeletingComments = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode(int index) {
    setState(() {
      if (!_isSelectionMode) {
        _isSelectionMode = true;
        _selectedCommentIndices.add(index);
      } else {
        _exitSelectionMode();
      }
    });
  }

  void _toggleCommentSelection(int index) {
    setState(() {
      if (_selectedCommentIndices.contains(index)) {
        _selectedCommentIndices.remove(index);
        if (_selectedCommentIndices.isEmpty) {
          _exitSelectionMode();
        }
      } else {
        _selectedCommentIndices.add(index);
      }
    });
  }

  void _selectAllComments() {
    setState(() {
      _selectedCommentIndices = Set.from(
        List.generate(_currentTask.comments.length, (index) => index),
      );
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedCommentIndices.clear();
    });
  }

  Future<void> _deleteSelectedComments() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        title: Text(
          LocaleKeys.deleteComments.tr(),
          style: TextStyle(color: Colors.white),
        ),

        content: Text(
          '${_selectedCommentIndices.length} ${LocaleKeys.deleteCommentsConfirmation.tr()}',
          style: const TextStyle(color: Colors.white70),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              LocaleKeys.delete.tr(),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeletingComments = true);

    try {
      final tasksProvider = context.read<ProviderAdminTasks>();

      // Get the comment IDs to delete
      final commentIdsToDelete = _selectedCommentIndices
          .map((index) => _currentTask.comments[index].id)
          .toList();

      // Delete comments (you'll need to implement this in your provider)
      final success = await tasksProvider.deleteComments(
        _currentTask.id,
        commentIdsToDelete,
      );

      if (success) {
        setState(() {
          // Remove deleted comments from local state
          final newComments = _currentTask.comments
              .asMap()
              .entries
              .where((entry) => !_selectedCommentIndices.contains(entry.key))
              .map((entry) => entry.value)
              .toList();

          _currentTask = TaskModel(
            id: _currentTask.id,
            title: _currentTask.title,
            description: _currentTask.description,
            assignedInspectorId: _currentTask.assignedInspectorId,
            assignedInspectorName: _currentTask.assignedInspectorName,
            relatedBranchId: _currentTask.relatedBranchId,
            relatedInspectionId: _currentTask.relatedInspectionId,
            status: _currentTask.status,
            priority: _currentTask.priority,
            dueDate: _currentTask.dueDate,
            comments: newComments,
            createdAt: _currentTask.createdAt,
            updatedAt: DateTime.now(),
          );
        });

        _exitSelectionMode();
        _showSnackBar(LocaleKeys.commentAddedSuccess.tr(), isError: false);
        widget.onTaskUpdated?.call();
      } else {
        _showSnackBar('${LocaleKeys.failedToAddComment.tr()}');
      }
    } catch (e) {
      _showSnackBar('${LocaleKeys.failedToAddComment.tr()}: ${e.toString()}');
    } finally {
      setState(() => _isDeletingComments = false);
    }
  }

  Future<void> _addComment() async {
    final commentText = _commentController.text.trim();

    if (commentText.isEmpty && _commentPhotos.isEmpty) {
      _showSnackBar(LocaleKeys.pleaseAddCommentOrPhoto.tr());
      return;
    }

    setState(() => _isAddingComment = true);

    try {
      final tasksProvider = context.read<ProviderAdminTasks>();
      tasksProvider.commentController.text = commentText;

      for (final photo in _commentPhotos) {
        tasksProvider.addCommentPhoto(photo);
      }

      final comment = await tasksProvider.addComment(_currentTask.id, context);

      if (comment != null) {
        setState(() {
          _currentTask = TaskModel(
            id: _currentTask.id,
            title: _currentTask.title,
            description: _currentTask.description,
            assignedInspectorId: _currentTask.assignedInspectorId,
            assignedInspectorName: _currentTask.assignedInspectorName,
            relatedBranchId: _currentTask.relatedBranchId,
            relatedInspectionId: _currentTask.relatedInspectionId,
            status: _currentTask.status,
            priority: _currentTask.priority,
            dueDate: _currentTask.dueDate,
            comments: [..._currentTask.comments, comment],
            createdAt: _currentTask.createdAt,
            updatedAt: DateTime.now(),
          );
          _showCommentInput = false;
        });

        _commentController.clear();
        _commentPhotos.clear();
        _showSnackBar(LocaleKeys.commentAddedSuccess.tr(), isError: false);
        widget.onTaskUpdated?.call();
      }
    } catch (e) {
      _showSnackBar('${LocaleKeys.failedToAddComment.tr()}: ${e.toString()}');
    } finally {
      setState(() => _isAddingComment = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _commentPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      _showSnackBar('${LocaleKeys.failedToPickImage.tr()}: ${e.toString()}');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _commentPhotos.removeAt(index);
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    showSnakBarr(context, message);
  }

  Color _getStatusColor() {
    switch (_currentTask.status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_currentTask.status) {
      case 'pending':
        return LocaleKeys.pending.tr();
      case 'in_progress':
        return LocaleKeys.inProgress.tr();
      case 'completed':
        return LocaleKeys.completed.tr();
      default:
        return LocaleKeys.unknown.tr();
    }
  }

  Color _getPriorityColor() {
    switch (_currentTask.priority) {
      case 'high':
        return const Color(0xFFEF5350);
      case 'medium':
        return const Color(0xFFFFA726);
      case 'low':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final priorityColor = _getPriorityColor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.lightBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  if (_isSelectionMode)
                    IconButton(
                      onPressed: _exitSelectionMode,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    Expanded(
                      child: Text(
                        _currentTask.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  if (_isSelectionMode) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_selectedCommentIndices.length} ${LocaleKeys.selected.tr()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_selectedCommentIndices.length <
                        _currentTask.comments.length)
                      TextButton(
                        onPressed: _selectAllComments,
                        child: Text(
                          LocaleKeys.selectAll.tr(),
                          style: TextStyle(color: AppColors.primaryRed),
                        ),
                      ),
                    IconButton(
                      onPressed: _isDeletingComments
                          ? null
                          : _deleteSelectedComments,
                      icon: _isDeletingComments
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.red),
                              ),
                            )
                          : const Icon(Icons.delete_rounded, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ] else
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (!_isSelectionMode) ...[
                    // Status and Priority Badges
                    Row(
                      children: [
                        _buildBadge(
                          _getStatusText(),
                          statusColor,
                          Icons.circle,
                        ),
                        const SizedBox(width: 10),
                        _buildBadge(
                          '${_currentTask.priority[0].toUpperCase()}${_currentTask.priority.substring(1)} ${LocaleKeys.priority.tr()}',
                          priorityColor,
                          Icons.flag_rounded,
                        ),

                        Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showTaskForm(context, _currentTask);
                          },
                          child: Text(LocaleKeys.edit.tr()),
                        ),
                        TextButton(
                          child: Text(LocaleKeys.delete.tr()),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(LocaleKeys.deleteTask.tr()),
                                content: Text(
                                  LocaleKeys.deleteTaskConfirmation.tr(),
                                ),

                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop(false);
                                    },
                                    child: Text(LocaleKeys.cancel.tr()),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop(true);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      LocaleKeys.delete.tr(),
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                final tasksProvider = context
                                    .read<ProviderAdminTasks>();
                                final success = await tasksProvider.deleteTask(
                                  _currentTask.id,
                                );
                                if (success) {
                                  showSnakBarr(
                                    context,
                                    LocaleKeys.taskDeleted.tr(),
                                  );
                                } else {
                                  throw Exception(
                                    LocaleKeys.failedToDeleteTask.tr(),
                                  );
                                }
                              } catch (e) {
                                showSnakBarr(
                                  context,
                                  '${LocaleKeys.failedToDeleteTask.tr()}: $e',
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description Card
                    _buildSectionCard(
                      title: LocaleKeys.description.tr(),
                      child: Text(
                        _currentTask.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Task Information Card
                    _buildSectionCard(
                      title: LocaleKeys.taskInformation.tr(),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.person_outline_rounded,
                            label: LocaleKeys.assignedTo.tr(),
                            value: _currentTask.assignedInspectorName,
                          ),
                          if (_currentTask.dueDate != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.event_rounded,
                              label: LocaleKeys.dueDate.tr(),
                              value: DateFormat(
                                'MMM dd, yyyy',
                              ).format(_currentTask.dueDate!),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.access_time_rounded,
                            label: LocaleKeys.created.tr(),
                            value: _currentTask.createdAt
                                .getFormattedDateTime(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Comments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocaleKeys.noCommentsYet.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentTask.comments.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Comments List
                  if (_currentTask.comments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocaleKeys.noCommentsYet.tr(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_currentTask.comments.length, (index) {
                      final comment = _currentTask.comments[index];
                      final isLast = index == _currentTask.comments.length - 1;
                      final isSelected = _selectedCommentIndices.contains(
                        index,
                      );

                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                        child: _buildCommentCard(comment, index, isSelected),
                      );
                    }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButtonLocation: _showCommentInput
          ? FloatingActionButtonLocation.centerDocked
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: _isSelectionMode
          ? null
          : !_showCommentInput
          ? OutlinedButton.icon(
              onPressed: () => setState(() => _showCommentInput = true),
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: Text(LocaleKeys.addComment.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.9),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildCommentInput(),
            ),
    );
  }

  void _showTaskForm(BuildContext context, TaskModel? task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskAddEditSheet(task: task, onSuccess: () {}),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(comment, int index, bool isSelected) {
    return GestureDetector(
      onLongPress: () => _toggleSelectionMode(index),
      onTap: _isSelectionMode ? () => _toggleCommentSelection(index) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryRed.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 2),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected
                      ? AppColors.primaryRed
                      : Colors.white.withValues(alpha: 0.3),
                  size: 24,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryRed.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          comment.userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.userName,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM dd · HH:mm',
                              ).format(comment.timestamp),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (comment.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      comment.text,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (comment.photos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: comment.photos.map<Widget>((photoUrl) {
                        return InkWell(
                          onTap: _isSelectionMode
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImageViewer(
                                        images: comment.photos,
                                        initialIndex: comment.photos.indexOf(
                                          photoUrl,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            controller: _commentController,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
            maxLines: 5,
            minLines: 1,
            decoration: InputDecoration(
              isDense: true,
              hintText: LocaleKeys.writeYourComment.tr(),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          if (_commentPhotos.isNotEmpty) ...[
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _commentPhotos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final photo = entry.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(photo, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(
                    Icons.image_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  iconSize: 22,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showCommentInput = false;
                      _commentController.clear();
                      _commentPhotos.clear();
                    });
                  },
                  child: Text(
                    LocaleKeys.cancel.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isAddingComment ? null : _addComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isAddingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          LocaleKeys.post.tr(),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
