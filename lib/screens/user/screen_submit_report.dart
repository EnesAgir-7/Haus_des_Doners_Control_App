import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/widgets/custom_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import '../../core/constants/app_colors.dart';
import '../../models/branch_model.dart';
import '../../providers/provider_control.dart';
import '../../translations/locale_keys.g.dart';
import '../../widgets/app_button.dart';

class ScreenSubmitReport extends StatefulWidget {
  final BranchModel? selectedBranch;
  final String? branchId;
  final String? branchTemplateId;
  final String? from;

  const ScreenSubmitReport({
    super.key,
    this.selectedBranch,
    this.from = "",
    this.branchId,
    this.branchTemplateId,
  });

  @override
  State<ScreenSubmitReport> createState() => _ScreenSubmitReportState();
}

class _ScreenSubmitReportState extends State<ScreenSubmitReport>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _overallNotesController = TextEditingController();
  late AnimationController _headerAnimController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );
    _headerAnimController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controlProvider = context.read<ProviderControl>();
      controlProvider.initialize(
        widget.selectedBranch,
        widget.branchId!,
        widget.branchTemplateId!,
      );
    });
  }

  @override
  void dispose() {
    _overallNotesController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(String category) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null || !mounted) return;

      final file = File(photo.path);
      final provider = context.read<ProviderControl>();

      if (provider.getCategoryPhotos(category).length >= 4) {
        if (mounted) showSnakBarr(context, LocaleKeys.maximum_photos.tr());
        return;
      }

      provider.addCategoryPhoto(category, file);
    } catch (e, st) {
      debugPrint('Error taking photo: $e\n$st');
      if (mounted) {
        showSnakBarr(context, LocaleKeys.error_taking_photo.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBodyBehindAppBar: true,

      body: Consumer<ProviderControl>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlack,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading inspection...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          final template = provider.selectedTemplate;

          return Stack(
            children: [
              // Gradient Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryRed.withValues(alpha: 0.1),
                      AppColors.primaryDark,
                      AppColors.primaryDark,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),

              Column(
                children: [
                  // Enhanced Header
                  FadeTransition(
                    opacity: _headerAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(_headerAnimation),
                      child: _buildEnhancedHeader(provider),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (template != null)
                            ...template.categories.asMap().entries.map((entry) {
                              return TweenAnimationBuilder<double>(
                                duration: Duration(
                                  milliseconds: 400 + (entry.key * 100),
                                ),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildEnhancedQuestionCard(
                                  title: entry.value.title,
                                  category: entry.value.categoryId,
                                  score: provider.getCategoryScore(
                                    entry.value.categoryId,
                                  ),
                                  photos: provider.getCategoryPhotos(
                                    entry.value.categoryId,
                                  ),
                                  notes: provider.getCategoryNotes(
                                    entry.value.categoryId,
                                  ),
                                  onScoreChanged: (val) =>
                                      provider.setCategoryScore(
                                        entry.value.categoryId,
                                        val,
                                      ),
                                  onNotesChanged: (val) =>
                                      provider.setCategoryNotes(
                                        entry.value.categoryId,
                                        val,
                                      ),
                                  onPhotoRemoved: (val) =>
                                      provider.removeCategoryPhoto(
                                        entry.value.categoryId,
                                        val,
                                      ),
                                ),
                              );
                            }).toList()
                          else
                            _buildEmptyState(),

                          const SizedBox(height: 16),
                          _buildEnhancedOverallNotes(provider),
                          const SizedBox(height: 16),
                          _buildEnhancedSignatureSection(provider),
                          const SizedBox(height: 24),
                          _buildEnhancedActions(provider),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Upload Progress Overlay
              if (provider.isUploading) _buildEnhancedUploadOverlay(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhancedHeader(ProviderControl provider) {
    return SafeArea(
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.selectedBranch?.name ??
                            LocaleKeys.branch_inspection.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.primaryRed,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              provider.selectedBranch?.address ?? '',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuestionCard({
    required String title,
    required String category,
    required int score,
    required List<File> photos,
    required String notes,
    required Function(int) onScoreChanged,
    required Function(String) onNotesChanged,
    required Function(File) onPhotoRemoved,
  }) {
    final List<Map<String, dynamic>> ratings = [
      {'emoji': '😃', 'label': 'Excellent', 'color': Colors.green},
      {'emoji': '🙂', 'label': 'Good', 'color': Colors.lightGreen},
      {'emoji': '😐', 'label': 'Fair', 'color': Colors.orange},
      {'emoji': '😞', 'label': 'Poor', 'color': Colors.red},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: score > 0
              ? AppColors.primaryRed.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: score > 0 ? 2 : 1,
        ),
        boxShadow: score > 0
            ? [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Title Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: score > 0
                  ? LinearGradient(
                      colors: [
                        AppColors.primaryRed.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    )
                  : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: score > 0
                        ? AppColors.primaryRed.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.checklist_rounded,
                    color: score > 0 ? AppColors.primaryRed : Colors.white54,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (score > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryRed,
                          AppColors.primaryRed.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRed.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$score/4',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Rating Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: List.generate(4, (index) {
                final rating = index + 1;
                final isSelected = score == rating;
                final ratingData = ratings[index];

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => onScoreChanged(rating),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        height: isSelected ? 100 : 80,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryRed,
                                    AppColors.primaryRed.withValues(alpha: 0.8),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.05),
                                    Colors.white.withValues(alpha: 0.02),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryRed
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryRed.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ratingData['emoji'],
                              style: TextStyle(fontSize: isSelected ? 28 : 24),
                            ),
                            Text(
                              rating.toString(),
                              style: TextStyle(
                                fontSize: isSelected ? 20 : 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                            if (isSelected) ...[
                              Text(
                                ratingData['label'],
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Notes TextField
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onNotesChanged,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '${LocaleKeys.add_notes_optional.tr()} 📝',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryRed,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),

          // Photos Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppButton(
                  text: '${LocaleKeys.take_photo.tr()} (${photos.length}/4)',
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  icon: photos.length < 4
                      ? Icons.camera_alt
                      : Icons.check_circle,
                  onPressed: photos.length < 4
                      ? () => _takePhoto(category)
                      : null,
                  backgroundColor: photos.length < 4
                      ? AppColors.primaryRed
                      : Colors.green,
                  height: 48,
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Transform.scale(scale: value, child: child);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      photos[index],
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => onPhotoRemoved(photos[index]),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red,
                                            Colors.red.shade700,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOverallNotes(ProviderControl provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed.withValues(alpha: 0.2),
                      AppColors.primaryRed.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.note_alt_outlined,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocaleKeys.overall_notes.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _overallNotesController,
              onChanged: provider.setOverallNotes,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '${LocaleKeys.general_comments.tr()} 💭',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSignatureSection(ProviderControl provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: provider.hasAllSignatures
              ? AppColors.primaryRed.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: provider.hasAllSignatures ? 2 : 1,
        ),
        boxShadow: provider.hasAllSignatures
            ? [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: provider.hasAllSignatures
                        ? [
                            Colors.green.withValues(alpha: 0.2),
                            Colors.green.withValues(alpha: 0.1),
                          ]
                        : [
                            AppColors.primaryRed.withValues(alpha: 0.2),
                            AppColors.primaryRed.withValues(alpha: 0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.draw_outlined,
                  color: provider.hasAllSignatures
                      ? Colors.green
                      : AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  LocaleKeys.signatures.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (provider.hasAllSignatures)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Color(0xFF45B649)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        LocaleKeys.complete.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Inspector Signature
          _buildEnhancedSignatureCard(
            title: LocaleKeys.inspector_signature.tr(),
            subtitle: LocaleKeys.your_signature.tr(),
            signature: provider.inspectorSignature,
            icon: Icons.person_outline,
            onTap: () => _showEnhancedSignatureDialog(
              context,
              title: LocaleKeys.inspector_signature.tr(),
              onSave: (signature) {
                provider.setInspectorSignature(signature);
              },
            ),
            onClear: () => provider.setInspectorSignature(null),
          ),

          const SizedBox(height: 12),

          // Branch Representative Signature
          _buildEnhancedSignatureCard(
            title: LocaleKeys.branch_representative.tr(),
            subtitle: LocaleKeys.branch_manager_signature.tr(),
            signature: provider.branchSignature,
            icon: Icons.business_outlined,
            onTap: () => _showEnhancedSignatureDialog(
              context,
              title: LocaleKeys.branch_representative.tr(),
              onSave: (signature) {
                provider.setBranchSignature(signature);
              },
            ),
            onClear: () => provider.setBranchSignature(null),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSignatureCard({
    required String title,
    required String subtitle,
    required Uint8List? signature,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final bool hasSigned = signature != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: hasSigned
              ? LinearGradient(
                  colors: [
                    AppColors.primaryRed.withValues(alpha: 0.1),
                    AppColors.primaryRed.withValues(alpha: 0.05),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSigned
                ? AppColors.primaryRed.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
            width: hasSigned ? 2 : 1,
          ),
          boxShadow: hasSigned
              ? [
                  BoxShadow(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: hasSigned
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryRed,
                          AppColors.primaryRed.withValues(alpha: 0.8),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: hasSigned
                    ? [
                        BoxShadow(
                          color: AppColors.primaryRed.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 24,
                color: hasSigned ? Colors.white : Colors.white54,
              ),
            ),
            const SizedBox(width: 16),

            // Text & Signature Preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasSigned)
                    Container(
                      height: 50,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(signature, fit: BoxFit.contain),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.gesture, color: Colors.white38, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Action Button
            if (hasSigned)
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  tooltip: "Clear",
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: Colors.white38,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActions(ProviderControl provider) {
    final isEnabled = provider.isFormValid && provider.hasAllSignatures;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: AppButton(
              isLoading: provider.isSubmittingOrUploading,
              text: "Preview PDF",
              icon: Icons.preview_outlined,
              onPressed: isEnabled ? () => provider.previewPDF(context) : null,
              backgroundColor: isEnabled
                  ? AppColors.amber
                  : Colors.grey.shade800,
              textStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isEnabled ? AppColors.primaryDark : Colors.white38,
              ),
              height: 56,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: AppButton(
              isLoading: provider.isSubmittingOrUploading,
              text: LocaleKeys.submit_inspection.tr(),
              icon: Icons.check_circle_outline,
              onPressed: isEnabled ? () => _submitInspection(provider) : null,
              backgroundColor: isEnabled
                  ? AppColors.primaryRed
                  : Colors.grey.shade800,
              textStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : Colors.white38,
              ),
              height: 56,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedUploadOverlay(ProviderControl provider) {
    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.lightBlack,
                AppColors.lightBlack.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryRed.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: provider.uploadProgress,
                      color: AppColors.primaryRed,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryRed.withValues(alpha: 0.2),
                          AppColors.primaryRed.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: AppColors.primaryRed,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                LocaleKeys.uploading_photos.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed.withValues(alpha: 0.2),
                      AppColors.primaryRed.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(provider.uploadProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please wait...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            LocaleKeys.no_template.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitInspection(ProviderControl provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.help_outline,
                color: AppColors.primaryRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocaleKeys.submit_inspection_question.tr(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          LocaleKeys.submit_inspection_warning.tr(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryRed,
                  AppColors.primaryRed.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                LocaleKeys.submit.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await provider.submitInspection();

    if (success && mounted) {
      showSnakBarr(context, LocaleKeys.inspection_submitted.tr());

      if (mounted) {
        if (widget.from == AppConstants.details)
          Navigator.maybeOf(context)!.pop();
        Navigator.pop(context);
      }
    } else if (mounted && provider.errorMessage != null) {
      showSnakBarr(context, provider.errorMessage.toString());
    }
  }

  void _showEnhancedSignatureDialog(
    BuildContext context, {
    required String title,
    required Function(Uint8List) onSave,
  }) {
    final SignatureController controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.lightBlack,
                AppColors.lightBlack.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryRed.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed.withValues(alpha: 0.15),
                      AppColors.primaryRed.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryRed,
                            AppColors.primaryRed.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.draw,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Signature Pad
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryRed.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Signature(
                          controller: controller,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gesture, color: Colors.white38, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          LocaleKeys.sign_here.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.clear(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(LocaleKeys.clear.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.7),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryRed,
                              AppColors.primaryRed.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (controller.isEmpty) {
                              showSnakBarr(
                                context,
                                LocaleKeys.please_sign_first.tr(),
                              );
                              return;
                            }

                            final signature = await controller.toPngBytes();
                            if (signature != null) {
                              onSave(signature);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(LocaleKeys.save_signature.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
