import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/task_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../providers/provider_tasks.dart';
import '../screens/screen_full_image.dart';

class TaskDetailsSheet extends StatefulWidget {
  final TaskModel task;
  final ProviderTasks provider;

  const TaskDetailsSheet({required this.task, required this.provider});

  @override
  State<TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<TaskDetailsSheet> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    super.dispose();
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
        widget.provider.addCommentPhoto(File(image.path));
      }
    } catch (e) {
      showSnakBarr(
        context,
        '${LocaleKeys.failedToPickImage.tr()}: ${e.toString()}',
      );
    }
  }

  void _removePhoto(int index) {
    widget.provider.removeCommentPhoto(index);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return AnimatedPadding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: viewInsets.bottom + 20,
          ),
          duration: const Duration(milliseconds: 100),
          child: Column(
            children: [
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      widget.task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status and Priority
                    Row(
                      children: [
                        _buildDetailBadge(
                          icon: Icons.flag,
                          label: _getPriorityText(widget.task.priority),
                          color: _getPriorityColor(widget.task.priority),
                        ),
                        const SizedBox(width: 12),
                        _buildDetailBadge(
                          icon: Icons.schedule,
                          label: _getStatusText(widget.task.status),
                          color: _getStatusColor(widget.task.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      LocaleKeys.description.tr(),
                      style: const TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.task.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Meta info
                    if (widget.task.dueDate != null) ...[
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: LocaleKeys.due_date.tr(),
                        value:
                            '${widget.task.dueDate!.day}/${widget.task.dueDate!.month}/${widget.task.dueDate!.year}',
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildInfoRow(
                      icon: Icons.person,
                      label: LocaleKeys.assignInspector.tr(),
                      value: widget.task.assignedInspectorName,
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF3A3A3A)),
                    const SizedBox(height: 16),

                    // Comments section
                    _buildCommentsSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Fixed bottom section (Comment input and action buttons)
              if (!widget.task.isCompleted) ...[
                const Divider(color: Color(0xFF3A3A3A), height: 1),
                const SizedBox(height: 12),
                _buildCommentInputField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.task.isPending)
                      Expanded(
                        child: _buildActionButton(
                          label: LocaleKeys.start.tr(),
                          icon: Icons.play_arrow,
                          color: const Color(0xFFFFA726),
                          onPressed: () {
                            widget.provider.markAsInProgress(
                              widget.task.id,
                              widget.task.assignedInspectorId,
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    if (widget.task.isInProgress) ...[
                      Expanded(
                        child: _buildActionButton(
                          label: LocaleKeys.complete.tr(),
                          icon: Icons.check_circle,
                          color: AppColors.green,
                          onPressed: () {
                            widget.provider.markAsCompleted(
                              widget.task.id,
                              widget.task.assignedInspectorId,
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInputField() {
    return Consumer<ProviderTasks>(
      builder: (context, taskCont, child) {
        return Stack(
          children: [
            AbsorbPointer(
              absorbing: taskCont.isAddingComment, // disable all taps
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
                ),
                child: Column(
                  children: [
                    // Text input row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: taskCont.commentController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: LocaleKeys.addComment.tr(),
                              hintStyle: const TextStyle(
                                color: Color(0xFF606060),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        // Image picker button
                        IconButton(
                          icon: const Icon(
                            Icons.image_rounded,
                            color: Color(0xFF808080),
                          ),
                          onPressed: _pickImage,
                        ),
                        // Send button
                        IconButton(
                          icon: taskCont.isAddingComment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: AppColors.primaryRed),
                          onPressed: taskCont.isAddingComment
                              ? null
                              : () async {
                                  final TaskCommentModel? comment = await widget
                                      .provider
                                      .addComment(widget.task.id, context);
                                  if (comment != null) {
                                    FocusScope.of(context).unfocus();
                                    setState(() {
                                      widget.task.comments.add(comment);
                                    });
                                  }
                                },
                        ),
                      ],
                    ),

                    // Photo previews
                    if (taskCont.commentPhotos.isNotEmpty) ...[
                      const Divider(color: Color(0xFF3A3A3A), height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: taskCont.commentPhotos.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final photo = entry.value;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF3A3A3A),
                                      width: 1,
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
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
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
                  ],
                ),
              ),
            ),

            // Blur overlay when loading
            if (taskCont.isAddingComment)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        Icon(icon, size: 18, color: const Color(0xFF808080)),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(color: Color(0xFF808080), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    if (widget.task.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            LocaleKeys.no_comments.tr(),
            style: const TextStyle(color: Color(0xFF606060), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: widget.task.comments.map((comment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFE53935),
                    child: Text(
                      comment.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTimestamp(comment.timestamp),
                          style: const TextStyle(
                            color: Color(0xFF606060),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (comment.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  comment.text,
                  style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13),
                ),
              ],
              // Photo gallery
              if (comment.photos.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: comment.photos.map<Widget>((photoUrl) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              images: comment.photos,
                              initialIndex: comment.photos.indexOf(photoUrl),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3A3A3A)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFF1A1A1A),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Color(0xFF606060),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF1A1A1A),
                                child: const Icon(
                                  Icons.broken_image_rounded,
                                  color: Color(0xFF606060),
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
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case AppConstants.high:
        return AppColors.primaryRed;
      case AppConstants.medium:
        return const Color(0xFFFFA726);
      case AppConstants.low:
      default:
        return const Color(0xFF4CAF50);
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case AppConstants.high:
        return LocaleKeys.high.tr();
      case AppConstants.medium:
        return LocaleKeys.medium.tr();
      case AppConstants.low:
      default:
        return LocaleKeys.low.tr();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.completed:
        return const Color(0xFF4CAF50);
      case AppConstants.inProgress:
        return const Color(0xFFFFA726);
      case AppConstants.pending:
      default:
        return const Color(0xFF808080);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.completed:
        return LocaleKeys.completed.tr();
      case AppConstants.inProgress:
        return LocaleKeys.in_progress.tr();
      case AppConstants.pending:
      default:
        return LocaleKeys.pending.tr();
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return LocaleKeys.just_now.tr();
    } else if (difference.inHours < 1) {
      return LocaleKeys.minutes_ago.tr().replaceAll(
        AppConstants.count,
        difference.inMinutes.toString(),
      );
    } else if (difference.inDays < 1) {
      return LocaleKeys.hours_ago.tr().replaceAll(
        AppConstants.count,
        difference.inHours.toString(),
      );
    } else if (difference.inDays < 7) {
      return LocaleKeys.days_ago.tr().replaceAll(
        AppConstants.count,
        difference.inDays.toString(),
      );
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
