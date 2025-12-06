import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/constants/app_colors.dart';
import '../../../helpers/app_helpers.dart';
import '../../../models/training_video_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../branch/screens/screen_video_player.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../../inspector/widgets/custom_field.dart';
import '../admin_providers/provider_admin_trainings.dart';

//TODO: locale

class ScreenAdminBranchTrainings extends StatefulWidget {
  final String branchId;
  const ScreenAdminBranchTrainings({super.key, required this.branchId});

  @override
  State<ScreenAdminBranchTrainings> createState() =>
      _ScreenAdminBranchTrainingsState();
}

class _ScreenAdminBranchTrainingsState
    extends State<ScreenAdminBranchTrainings> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminTrainingVideosProvider>(
        context,
        listen: false,
      ).loadBranchVideos(widget.branchId);
    });
  }

  Future<void> _showAddVideoDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final durationController = TextEditingController();
    final descriptionController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      color: AppColors.primaryRed,
                      size: 28,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Add Training Video",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomField(
                  controller: titleController,
                  label: 'Title',
                  hint: 'Enter title',
                  icon: Icons.title,
                ),

                const SizedBox(height: 8),

                CustomField(
                  controller: urlController,
                  label: 'Video URL',
                  hint: 'https://youtube.com/…',
                  icon: Icons.link,
                ),

                const SizedBox(height: 8),

                CustomField(
                  controller: durationController,
                  label: 'Duration (mm:ss)',
                  hint: '15:30',
                  icon: Icons.access_time,
                ),

                const SizedBox(height: 8),

                CustomField(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'Enter description',
                  icon: Icons.description,
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        LocaleKeys.cancelButton.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final url = urlController.text.trim();
                        // ignore: unused_local_variable
                        final duration = durationController.text.trim();
                        final description = descriptionController.text.trim();

                        if (title.isEmpty || url.isEmpty) {
                          showCustomSnackBar(context, "Fill all fields");
                          return;
                        }

                        final provider =
                            Provider.of<AdminTrainingVideosProvider>(
                              context,
                              listen: false,
                            );

                        final ok = await provider.addVideo(
                          TrainingVideoModel(
                            description: description,
                            name: title,
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            videoUrl: url,
                            branchId: widget.branchId,
                            createdAt: DateTime.now(),
                          ),
                          context: context,
                        );

                        Navigator.pop(context);
                        if (!ok) {
                          // provider already shows error
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(LocaleKeys.add.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LocaleKeys.delete.tr()),
        content: const Text("Delete this video?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.cancelButton.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<AdminTrainingVideosProvider>(
        context,
        listen: false,
      );

      final ok = await provider.deleteVideo(id, context: context);
      if (!ok) {
        // provider already showed error via snack
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminTrainingVideosProvider>(context);
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final crossAxisCount = isTablet ? 3 : 2;

    return Scaffold(
      appBar: CustomAppBar(title: LocaleKeys.training_videos.tr()),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryRed,
        onPressed: () => _showAddVideoDialog(context),
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null
            ? Center(
                child: Text(
                  provider.errorMessage!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              )
            : provider.videos.isEmpty
            ? Center(
                child: Text(
                  "No videos found",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final video = provider.videos[index];
                        return _buildTrainingCard(context, video, index);
                      }, childCount: provider.videos.length),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTrainingCard(
    BuildContext context,
    TrainingVideoModel video,
    int index,
  ) {
    final thumbnailUrl = getThumbnailUrl(video.videoUrl);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenVideoPlayer(
              videoTitle: video.name,
              videoUrl: video.videoUrl,
              moduleNumber: index + 1,
              videoDescription: video.description.isNotEmpty
                  ? video.description
                  : 'Training Video',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Video Thumbnail Section
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Thumbnail Image
                          if (thumbnailUrl != null)
                            Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildFallbackThumbnail();
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildFallbackThumbnail();
                                  },
                            )
                          else
                            _buildFallbackThumbnail(),

                          // Dark overlay for better play button visibility
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),

                          // Play Button
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed.withValues(
                                  alpha: 0.9,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content Section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Flexible(
                          child: Text(
                            video.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ),

                        // Description
                        if (video.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              video.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            /// --- Delete Menu ---
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PopupMenuButton(
                  color: AppColors.primaryDark,
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  onSelected: (value) {
                    if (value == "delete") {
                      _confirmDelete(context, video.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocaleKeys.delete.tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fallback thumbnail widget
  Widget _buildFallbackThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed.withValues(alpha: 0.3),
            AppColors.primaryDark.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.video_library_outlined,
          size: 48,
          color: Colors.white54,
        ),
      ),
    );
  }
}
