import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/widgets/custom_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import '../../core/constants/app_colors.dart';
import '../../models/branch_model.dart';
import '../../providers/provider_control.dart';
import '../../translations/locale_keys.g.dart';
import '../../widgets/app_button.dart';

class ControlPage extends StatefulWidget {
  final BranchModel? selectedBranch;
  final String? branchId;
  final String? branchTemplateId;

  const ControlPage({
    super.key,
    this.selectedBranch,
    this.branchId,
    this.branchTemplateId,
  });

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _overallNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();

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
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Consumer<ProviderControl>(
          builder: (context, cont, child) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                cont.selectedBranch?.name ?? LocaleKeys.branch_inspection.tr(),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              subtitle: Text(
                cont.selectedBranch?.address ??
                    LocaleKeys.branch_inspection.tr(),
              ),
            );
          },
        ),
      ),
      body: Consumer<ProviderControl>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }
          final template = provider.selectedTemplate;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Branch Info Card
                    // _buildBranchInfoCard(),
                    // SizedBox(height: 16),
                    if (template != null)
                      ...template.categories.map((category) {
                        return _buildQuestionCard(
                          title: category.title,
                          category: category.categoryId,
                          score: provider.getCategoryScore(category.categoryId),
                          photos: provider.getCategoryPhotos(
                            category.categoryId,
                          ),
                          notes: provider.getCategoryNotes(category.categoryId),
                          onScoreChanged: (val) => provider.setCategoryScore(
                            category.categoryId,
                            val,
                          ),
                          onNotesChanged: (val) => provider.setCategoryNotes(
                            category.categoryId,
                            val,
                          ),
                          onPhotoRemoved: (val) => provider.removeCategoryPhoto(
                            category.categoryId,
                            val,
                          ),
                        );
                      }).toList()
                    else
                      Text(LocaleKeys.no_template.tr()),

                    _buildOverallNotesSection(provider),

                    // SizedBox(height: 16),

                    // if (provider.totalScore > 0) _buildScorePreview(provider),
                    SizedBox(height: 16),
                    _buildSignatureSection(provider),
                    SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            isLoading: provider.isSubmittingOrUploading,
                            text: "Preview PDF",
                            icon: Icons.preview,
                            onPressed:
                                (provider.isFormValid &&
                                    provider.hasAllSignatures)
                                ? () => provider.previewPDF(context)
                                : null,
                            backgroundColor:
                                (provider.isFormValid &&
                                    provider.hasAllSignatures)
                                ? AppColors.amber
                                : Colors.grey,
                            textStyle: TextStyle(
                              fontSize: 16,
                              color:
                                  (provider.isFormValid &&
                                      provider.hasAllSignatures)
                                  ? AppColors.primaryDark
                                  : AppColors.white,
                            ),
                            height: 52,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            isLoading: provider.isSubmittingOrUploading,
                            text: LocaleKeys.submit_inspection.tr(),
                            icon: Icons.check_circle,
                            onPressed:
                                (provider.isFormValid &&
                                    provider.hasAllSignatures)
                                ? () => _submitInspection(provider)
                                : null,
                            backgroundColor:
                                (provider.isFormValid &&
                                    provider.hasAllSignatures)
                                ? AppColors.primaryRed
                                : Colors.grey,
                            height: 52,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),

              // Upload Progress Overlay
              if (provider.isUploading) _buildUploadOverlay(provider),
            ],
          );
        },
      ),
    );
  }

  // Widget _buildBranchInfoCard() {
  //   return Container(
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppColors.lightBlack,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppColors.primaryRed),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.location_on, color: AppColors.primaryRed, size: 20),
  //             SizedBox(width: 8),
  //             Expanded(
  //               child: Text(
  //                 _selectedBranch!.name,
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 8),
  //         Text(
  //           _selectedBranch!.address,
  //           style: TextStyle(color: Colors.white70, fontSize: 13),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildQuestionCard({
    required String title,
    required String category,
    required int score,
    required List<File> photos,
    required String notes,
    required Function(int) onScoreChanged,
    required Function(String) onNotesChanged,
    required Function(File) onPhotoRemoved,
  }) {
    final List<String> emojis = ['😃', '🙂', '😐', '😞'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: score > 0
              ? AppColors.primaryRed.withValues(alpha: 0.5)
              : Colors.white24,
          width: score > 0 ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Title
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (score > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$score/4',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Rating Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final rating = index + 1;
                final bool isSelected = score == rating;

                return GestureDetector(
                  onTap: () => onScoreChanged(rating),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 70 : 60,
                    height: isSelected ? 70 : 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryRed
                          : AppColors.lightBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryRed
                            : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                        SizedBox(height: 4),
                        if (isSelected)
                          Text(
                            emojis[index],
                            style: const TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Notes TextField
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: onNotesChanged,
              maxLines: 2,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: LocaleKeys.add_notes_optional.tr(),
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.lightBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryRed),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),

          // Photos Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  text: '${LocaleKeys.take_photo.tr()} (${photos.length}/4)',
                  textStyle: TextStyle(fontSize: 14),
                  icon: Icons.camera_alt,
                  onPressed: photos.length < 4
                      ? () => _takePhoto(category)
                      : null,
                  backgroundColor: photos.length < 4
                      ? AppColors.primaryRed
                      : Colors.grey,
                  height: 44,
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  photos[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => onPhotoRemoved(photos[index]),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildOverallNotesSection(ProviderControl provider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.overall_notes.tr(),
            style: TextStyle(
              color: AppColors.primaryRed,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _overallNotesController,
            onChanged: provider.setOverallNotes,
            maxLines: 4,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: LocaleKeys.general_comments.tr(),
              hintStyle: TextStyle(color: Colors.white38),
              filled: true,
              fillColor: AppColors.lightRed,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildScorePreview(ProviderControl provider) {
  //   return Container(
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppColors.primaryRed.withValues(alpha: 0.15),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppColors.primaryRed),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               LocaleKeys.total_score.tr(),
  //               style: TextStyle(color: Colors.white70, fontSize: 14),
  //             ),
  //             SizedBox(height: 4),
  //             Text(
  //               provider.totalScore.toStringAsFixed(1),
  //               style: TextStyle(
  //                 color: AppColors.primaryRed,
  //                 fontSize: 32,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         Icon(Icons.star, size: 48, color: AppColors.primaryRed),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildUploadOverlay(ProviderControl provider) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          margin: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: provider.uploadProgress,
                color: AppColors.primaryRed,
                backgroundColor: Colors.white24,
                strokeWidth: 6,
              ),
              SizedBox(height: 24),
              Text(
                LocaleKeys.uploading_photos.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${(provider.uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitInspection(ProviderControl provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        title: Text(LocaleKeys.submit_inspection_question.tr()),
        content: Text(LocaleKeys.submit_inspection_warning.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: Text(LocaleKeys.submit.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await provider.submitInspection();

    if (success && mounted) {
      showSnakBarr(context, LocaleKeys.inspection_submitted.tr());

      if (mounted) {
        Navigator.pop(context);
      }
    } else if (mounted && provider.errorMessage != null) {
      showSnakBarr(context, provider.errorMessage.toString());
    }
  }

  Widget _buildSignatureSection(ProviderControl provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: provider.hasAllSignatures
              ? AppColors.primaryRed.withValues(alpha: 0.5)
              : Colors.white24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_document, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.signatures.tr(), // Add to translations
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (provider.hasAllSignatures)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryRed.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primaryRed,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        LocaleKeys.complete.tr(),
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Inspector Signature
          _buildSignatureCard(
            title: LocaleKeys.inspector_signature.tr(),
            subtitle: LocaleKeys.your_signature.tr(),
            signature: provider.inspectorSignature,
            icon: Icons.person,
            onTap: () => _showSignatureDialog(
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
          _buildSignatureCard(
            title: LocaleKeys.branch_representative.tr(),
            subtitle: LocaleKeys.branch_manager_signature.tr(),
            signature: provider.branchSignature,
            icon: Icons.business,
            onTap: () => _showSignatureDialog(
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

  Widget _buildSignatureCard({
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasSigned
                ? AppColors.primaryRed.withValues(alpha: 0.3)
                : Colors.white24,
            width: hasSigned ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasSigned
                    ? AppColors.primaryRed.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: hasSigned ? AppColors.primaryRed : Colors.white54,
              ),
            ),
            const SizedBox(width: 12),

            // Text & Signature Preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (hasSigned)
                    Container(
                      height: 40,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(signature, fit: BoxFit.contain),
                      ),
                    )
                  else
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Action Button
            if (hasSigned)
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close, color: AppColors.primaryRed, size: 20),
                tooltip: "Clear",
              )
            else
              Icon(Icons.edit, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSignatureDialog(
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primaryRed.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.draw, color: AppColors.primaryRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),

              // Signature Pad
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Signature(
                          controller: controller,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      LocaleKeys.sign_here.tr(),
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.clear(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(LocaleKeys.clear.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
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
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
