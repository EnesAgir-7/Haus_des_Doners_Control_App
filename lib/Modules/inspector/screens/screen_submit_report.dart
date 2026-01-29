import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums.dart';
import '../../../models/branch_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../providers/provider_control.dart';
import '../widgets/app_button.dart';

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
  final Map<String, TextEditingController> _categoryNotesControllers = {};
  // Track which questions/categories are enabled (applicable). Default is true.
  final Map<String, bool> _enabledCategories = {};
  late AnimationController _headerAnimController;
  late Animation<double> _headerAnimation;
  Timer? _autoSaveTimer;
  String? _lastSavedHash;
  bool _isSaveDialogOpen = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controlProvider = context.read<ProviderControl>();

      controlProvider.initialize(
        widget.selectedBranch,
        widget.branchId!,
        widget.branchTemplateId!,
      );

      // Load draft report after initialization
      await _loadDraftReport(controlProvider);

      // Generate initial hash after loading
      _lastSavedHash = _generateStateHash(controlProvider);

      // Start auto-save timer
      _startAutoSaveTimer(controlProvider);
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _overallNotesController.dispose();
    for (final controller in _categoryNotesControllers.values) {
      controller.dispose();
    }
    _headerAnimController.dispose();
    super.dispose();
  }

  // Draft saving and loading methods
  String _getDraftKey() {
    return 'draft_report_${widget.branchId ?? widget.selectedBranch?.id ?? 'unknown'}';
  }

  bool _hasUnsavedData(ProviderControl provider) {
    // Check if any data has been entered
    bool hasScores = false;
    bool hasNotes = false;
    bool hasPhotos = false;

    if (provider.selectedTemplate != null) {
      for (final category in provider.selectedTemplate!.categories) {
        final categoryId = category.categoryId;
        // Skip disabled categories – they are considered not part of the form
        final isEnabled = _enabledCategories[categoryId] ?? true;
        if (!isEnabled) continue;

        // Check scores
        if (provider.getCategoryScore(categoryId) > 0) {
          hasScores = true;
        }

        // Check notes
        final controller = _categoryNotesControllers[categoryId];
        final noteText =
            controller?.text ?? provider.getCategoryNotes(categoryId);
        if (noteText.isNotEmpty) {
          hasNotes = true;
        }

        // Check photos
        if (provider.getCategoryPhotos(categoryId).isNotEmpty) {
          hasPhotos = true;
        }
      }
    }

    final hasOverallNotes = _overallNotesController.text.isNotEmpty;
    final hasSignatures =
        provider.inspectorSignature != null || provider.branchSignature != null;

    return hasScores ||
        hasNotes ||
        hasPhotos ||
        hasOverallNotes ||
        hasSignatures;
  }

  Future<String?> _saveDraftReport(ProviderControl provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = _getDraftKey();

      // Collect data from all categories
      final scores = <String, int>{};
      final notes = <String, String>{};
      final photosData = <String, List<String>>{};

      if (provider.selectedTemplate != null) {
        for (final category in provider.selectedTemplate!.categories) {
          final categoryId = category.categoryId;

          // Get scores
          final score = provider.getCategoryScore(categoryId);
          if (score > 0) {
            scores[categoryId] = score;
          }

          // Get notes from controller (which has the latest unsaved changes)
          final controller = _categoryNotesControllers[categoryId];
          final note =
              controller?.text ?? provider.getCategoryNotes(categoryId);
          if (note.isNotEmpty) {
            notes[categoryId] = note;
          }

          // Get photos and convert to base64
          final photos = provider.getCategoryPhotos(categoryId);
          if (photos.isNotEmpty) {
            final photoList = <String>[];
            for (final photo in photos) {
              try {
                final bytes = await photo.readAsBytes();
                final base64String = base64Encode(bytes);
                photoList.add(base64String);
              } catch (e) {
                // Skip photos that can't be read
                continue;
              }
            }
            if (photoList.isNotEmpty) {
              photosData[categoryId] = photoList;
            }
          }
        }
      }

      final draftData = {
        'scores': scores,
        'notes': notes,
        'overallNotes': _overallNotesController.text,
        'photos': photosData,
        // Persist which questions are enabled/disabled
        'enabledCategories': _enabledCategories.map(
          (key, value) => MapEntry(key, value),
        ),
        'inspectorSignature': provider.inspectorSignature != null
            ? base64Encode(provider.inspectorSignature!)
            : null,
        'branchSignature': provider.branchSignature != null
            ? base64Encode(provider.branchSignature!)
            : null,
        'savedAt': DateTime.now().toIso8601String(),
        'branchId': widget.branchId ?? widget.selectedBranch?.id ?? '',
        'branchTemplateId': widget.branchTemplateId ?? '',
      };

      final jsonData = jsonEncode(draftData);
      await prefs.setString(draftKey, jsonData);

      // Generate hash of what was saved
      final savedHash = _generateStateHash(provider);

      if (mounted) {
        console("Draft saved successfully");
        // showSnakBarr(context, 'Draft saved successfully');
      }

      return savedHash;
    } catch (e) {
      if (mounted) {
        console("Failed to save draft: $e");
        // showSnakBarr(context, 'Failed to save draft');
      }
      return null;
    }
  }

  Future<void> _loadDraftReport(ProviderControl provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = _getDraftKey();

      final jsonData = prefs.getString(draftKey);
      if (jsonData == null) return;

      final draftData = jsonDecode(jsonData) as Map<String, dynamic>;

      // Load scores
      final scores = draftData['scores'] as Map<String, dynamic>? ?? {};
      for (final entry in scores.entries) {
        provider.setCategoryScore(entry.key, entry.value as int);
      }

      // Load notes
      final notes = draftData['notes'] as Map<String, dynamic>? ?? {};
      for (final entry in notes.entries) {
        final noteText = entry.value as String;
        provider.setCategoryNotes(entry.key, noteText);
        // Also set the controller text
        if (!_categoryNotesControllers.containsKey(entry.key)) {
          _categoryNotesControllers[entry.key] = TextEditingController();
        }
        _categoryNotesControllers[entry.key]!.text = noteText;
      }

      // Load overall notes
      final overallNotes = draftData['overallNotes'] as String? ?? '';
      _overallNotesController.text = overallNotes;

      // Load enabled/disabled state for questions (optional)
      final enabledCategories =
          draftData['enabledCategories'] as Map<String, dynamic>? ?? {};
      _enabledCategories
        ..clear()
        ..addAll(
          enabledCategories.map((key, value) => MapEntry(key, value as bool)),
        );

      // ✅ CRITICAL: Also update the provider's enabled categories for validation
      provider.setEnabledCategories(_enabledCategories);

      // Load photos - Note: We need to add photos one by one since there's no bulk setter
      final photosData = draftData['photos'] as Map<String, dynamic>? ?? {};
      for (final entry in photosData.entries) {
        final categoryId = entry.key;
        final photoList = entry.value as List<dynamic>;

        for (final photoBase64 in photoList) {
          try {
            final bytes = base64Decode(photoBase64 as String);
            final tempDir = await Directory.systemTemp.createTemp();
            final tempFile = File(
              '${tempDir.path}/draft_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await tempFile.writeAsBytes(bytes);
            provider.addCategoryPhoto(categoryId, tempFile);
          } catch (e) {
            // Skip corrupted photos
            continue;
          }
        }
      }

      // Load signatures
      final inspectorSignatureBase64 =
          draftData['inspectorSignature'] as String?;
      if (inspectorSignatureBase64 != null) {
        try {
          provider.setInspectorSignature(
            base64Decode(inspectorSignatureBase64),
          );
        } catch (e) {
          // Skip corrupted signature
        }
      }

      final branchSignatureBase64 = draftData['branchSignature'] as String?;
      if (branchSignatureBase64 != null) {
        try {
          provider.setBranchSignature(base64Decode(branchSignatureBase64));
        } catch (e) {
          // Skip corrupted signature
        }
      }

      if (mounted) {
        showSnakBarr(context, 'Draft report loaded');
      }
    } catch (e) {
      if (mounted) {
        showSnakBarr(context, 'Failed to load draft report');
      }
    }
  }

  Future<void> _clearDraftReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = _getDraftKey();
      await prefs.remove(draftKey);
      _lastSavedHash = null;
      _enabledCategories.clear();
    } catch (e) {
      // Ignore errors when clearing draft
    }
  }

  // Generate a hash of current form state for change detection
  String _generateStateHash(ProviderControl provider) {
    final buffer = StringBuffer();

    // Add scores
    if (provider.selectedTemplate != null) {
      for (final category in provider.selectedTemplate!.categories) {
        final categoryId = category.categoryId;
        final score = provider.getCategoryScore(categoryId);
        buffer.write('score_$categoryId:$score|');

        // Add notes from controllers (latest state)
        final controller = _categoryNotesControllers[categoryId];
        final notes = controller?.text ?? provider.getCategoryNotes(categoryId);
        buffer.write('notes_$categoryId:$notes|');

        // Add photo count
        final photos = provider.getCategoryPhotos(categoryId);
        buffer.write('photos_$categoryId:${photos.length}|');

        // Add enabled/disabled state
        final isEnabled = _enabledCategories[categoryId] ?? true;
        buffer.write('enabled_$categoryId:$isEnabled|');
      }
    }

    // Add overall notes
    buffer.write('overall:${_overallNotesController.text}|');

    // Add signatures
    buffer.write('sig1:${provider.inspectorSignature != null}|');
    buffer.write('sig2:${provider.branchSignature != null}|');

    return buffer.toString();
  }

  // Auto-save method called every 10 seconds
  Future<void> _autoSaveDraft(ProviderControl provider) async {
    if (!mounted) return;

    // Check if there's any data to save
    if (!_hasUnsavedData(provider)) {
      // No data to save, clear any existing draft
      await _clearDraftReport();
      return;
    }

    // Generate current state hash
    final currentHash = _generateStateHash(provider);

    // Only save if state has changed
    if (currentHash == _lastSavedHash) {
      return; // No changes, skip saving
    }

    try {
      final savedHash = await _saveDraftReport(provider);
      if (savedHash != null) {
        _lastSavedHash = savedHash;
      }

      // Optional: Show subtle feedback (could be removed for less intrusive UX)
      if (mounted) {
        // You could add a small toast or indicator here if desired
        // showSnakBarr(context, 'Auto-saved');
      }
    } catch (e) {
      // Silently handle auto-save errors to not disturb user
      debugPrint('Auto-save failed: $e');
    }
  }

  Future<bool?> _showSaveDraftDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allow dismissal to continue working
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Unsubmitted Report',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey.shade400),
              onPressed: () => Navigator.pop(context, null), // Dismiss dialog
              tooltip: 'Continue Working',
            ),
          ],
        ),
        content: const Text(
          'You have an unsubmitted report. Do you want to save it as a draft?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No, Discard',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Save Draft'),
          ),
        ],
      ),
    );
  }

  void _startAutoSaveTimer(ProviderControl provider) {
    _autoSaveTimer?.cancel(); // Cancel any existing timer

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _autoSaveDraft(provider);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleBackPress(ProviderControl provider) async {
    if (_hasUnsavedData(provider)) {
      _isSaveDialogOpen = true;
      bool? shouldSave;
      try {
        shouldSave = await _showSaveDraftDialog();
        if (shouldSave == true) {
          final savedHash = await _saveDraftReport(provider);
          if (savedHash != null) {
            _lastSavedHash = savedHash;
          }
        } else if (shouldSave == false) {
          await _clearDraftReport();
        }
        // If shouldSave is null (dialog dismissed), do nothing and stay on screen
      } finally {
        _isSaveDialogOpen = false;
      }

      // Only navigate back if user chose an option (not dismissed)
      if (mounted && shouldSave != null) {
        Navigator.pop(context);
      }
    } else {
      // No unsaved data, safe to go back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickFromGallery(String category) async {
    try {
      final provider = context.read<ProviderControl>();
      final existingCount = provider.getCategoryPhotos(category).length;
      const maxPhotos = 4;

      if (existingCount >= maxPhotos) {
        if (mounted) showSnakBarr(context, LocaleKeys.maximum_photos.tr());
        return;
      }

      final List<XFile> selectedImages = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (selectedImages.isEmpty || !mounted) return;

      final totalAfterAdd = existingCount + selectedImages.length;

      // If user selects too many
      if (totalAfterAdd > maxPhotos) {
        if (mounted) {
          showSnakBarr(
            context,
            LocaleKeys.youCanOnlyUpload.tr().replaceFirst(
              '{maxPhotos}',
              maxPhotos.toString(),
            ),
          );
        }
      }

      // Only take up to the remaining allowed number
      final remaining = maxPhotos - existingCount;
      final allowedImages = selectedImages.take(remaining);

      for (final image in allowedImages) {
        final file = File(image.path);
        provider.addCategoryPhoto(category, file);
      }
    } catch (e, st) {
      debugPrint('Error picking from gallery: $e\n$st');
      if (mounted) {
        showSnakBarr(context, LocaleKeys.errorPickingFromGallery.tr());
      }
    }
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
    return PopScope(
      canPop:
          false, // Prevent default back behavior since we handle it manually
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // If already popped by system, do nothing
        if (didPop) {
          return;
        }

        // Prevent back navigation if save dialog is already open
        if (_isSaveDialogOpen) {
          return;
        }

        final provider = context.read<ProviderControl>();
        await _handleBackPress(provider);
      },
      child: Scaffold(
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
                      child: const CircularProgressIndicator(
                        color: AppColors.primaryRed,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      LocaleKeys.loadingInspection.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
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
                              ...template.categories.asMap().entries.map((
                                entry,
                              ) {
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
                                    maxScore: entry.value.maxScore,
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
                                    onNotesChanged: (val) {
                                      provider.setCategoryNotes(
                                        entry.value.categoryId,
                                        val,
                                      );
                                      // Also update the controller
                                      if (!_categoryNotesControllers
                                          .containsKey(
                                            entry.value.categoryId,
                                          )) {
                                        _categoryNotesControllers[entry
                                                .value
                                                .categoryId] =
                                            TextEditingController();
                                      }
                                      _categoryNotesControllers[entry
                                                  .value
                                                  .categoryId]!
                                              .text =
                                          val;
                                    },
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
                ...(provider.isSubmitting &&
                        provider.isUploading &&
                        provider.currentUploadStage != null
                    ? [_buildEnhancedUploadOverlay(provider)]
                    : []),
              ],
            );
          },
        ),
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
              onPressed: () async {
                final provider = context.read<ProviderControl>();
                await _handleBackPress(provider);
              },
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
                          const Icon(
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
    required int maxScore, // Add this parameter
    required List<File> photos,
    required String notes,
    required Function(int) onScoreChanged,
    required Function(String) onNotesChanged,
    required Function(File) onPhotoRemoved,
  }) {
    // Get or create controller for this category
    if (!_categoryNotesControllers.containsKey(category)) {
      _categoryNotesControllers[category] = TextEditingController(text: notes);
    }
    final notesController = _categoryNotesControllers[category]!;

    // Question enabled/disabled state (defaults to true)
    final bool isEnabled = _enabledCategories[category] ?? true;

    final bool isRequired = isEnabled && score >= 3;
    final List<Map<String, dynamic>> allRatings = [
      {
        'emoji': '😃',
        'label': LocaleKeys.excellent.tr(),
        'color': Colors.green,
      },
      {
        'emoji': '🙂',
        'label': LocaleKeys.good.tr(),
        'color': Colors.lightGreen,
      },
      {'emoji': '😐', 'label': LocaleKeys.fair.tr(), 'color': Colors.orange},
      {
        'emoji': '😕',
        'label': LocaleKeys.belowAverage.tr(),
        'color': Colors.deepOrange,
      },
      {'emoji': '😞', 'label': LocaleKeys.poor.tr(), 'color': Colors.red},
      {
        'emoji': '😢',
        'label': LocaleKeys.veryPoor.tr(),
        'color': Colors.red.shade900,
      },
    ];

    // Get only the ratings needed based on maxScore
    final List<Map<String, dynamic>> ratings = allRatings
        .take(maxScore)
        .toList();

    final card = Container(
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
              ? (ratings[score - 1]['color'] as Color).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: score > 0 ? 2 : 1,
        ),
        boxShadow: score > 0
            ? [
                BoxShadow(
                  color: (ratings[score - 1]['color'] as Color).withValues(
                    alpha: 0.15,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Title Header (with enable/disable switch) - ALWAYS INTERACTIVE
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: score > 0
                  ? LinearGradient(
                      colors: [
                        (ratings[score - 1]['color'] as Color).withValues(
                          alpha: 0.15,
                        ),
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
                        ? (ratings[score - 1]['color'] as Color).withValues(
                            alpha: 0.2,
                          )
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.checklist_rounded,
                    color: score > 0
                        ? ratings[score - 1]['color'] as Color
                        : Colors.white54,
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
                  Row(
                    children: [
                      Text(
                        '${allRatings[score - 1]['emoji']}',
                        style: const TextStyle(fontSize: 30),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ratings[score - 1]['color'] as Color,
                              (ratings[score - 1]['color'] as Color).withValues(
                                alpha: 0.8,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (ratings[score - 1]['color'] as Color)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$score/$maxScore',
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
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8, // Make switch smaller
                  child: Switch(
                    value: isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _enabledCategories[category] = value;
                        // Sync enabled categories with provider for validation
                        final provider = context.read<ProviderControl>();
                        provider.setEnabledCategories(_enabledCategories);

                        if (!value) {
                          // Clear score
                          provider.setCategoryScore(category, 0);
                          // Clear notes
                          provider.setCategoryNotes(category, '');
                          notesController.clear();
                          // Clear photos
                          final photosForCat = provider
                              .getCategoryPhotos(category)
                              .toList();
                          for (final photo in photosForCat) {
                            provider.removeCategoryPhoto(category, photo);
                          }
                        }
                      });
                    },
                    activeThumbColor: AppColors.primaryRed,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Card content (rating buttons, photos, notes) - DISABLED WHEN !isEnabled
          IgnorePointer(
            ignoring: !isEnabled,
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.4,
              child: Column(
                children: [
                  // Rating Buttons - Dynamic based on maxScore
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Row(
                      children: List.generate(maxScore, (index) {
                        final rating = index + 1;
                        final isSelected = score == rating;
                        final ratingData = ratings[index];
                        final ratingColor = ratingData['color'] as Color;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => onScoreChanged(rating),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            ratingColor,
                                            ratingColor.withValues(alpha: 0.8),
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.02,
                                            ),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? ratingColor
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: ratingColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      rating.toString(),
                                      style: TextStyle(
                                        fontSize: isSelected ? 23 : 20,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
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
                                        textAlign: TextAlign.center,
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
                        controller: notesController,
                        onChanged: onNotesChanged,
                        maxLines: 3,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: isRequired
                              ? '${LocaleKeys.add_notes_optional.tr()} 🛑 ${LocaleKeys.required.tr()}'
                              : '${LocaleKeys.add_notes_optional.tr()}',
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
                              color: score > 0
                                  ? ratings[score - 1]['color'] as Color
                                  : AppColors.primaryRed,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),

                  // Photos Section (unchanged)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          spacing: 13,
                          children: [
                            Expanded(
                              child: AppButton(
                                text:
                                    '${LocaleKeys.take_photo.tr()} (${photos.length}/4)',
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
                            ),
                            Expanded(
                              child: AppButton(
                                text:
                                    '${LocaleKeys.browse.tr()} (${photos.length}/4)',
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                icon: photos.length < 4
                                    ? Icons.camera_alt
                                    : Icons.check_circle,
                                onPressed: photos.length < 4
                                    ? () => _pickFromGallery(category)
                                    : null,
                                backgroundColor: photos.length < 4
                                    ? AppColors.primaryRed
                                    : Colors.green,
                                height: 48,
                              ),
                            ),
                          ],
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
                                  duration: Duration(
                                    milliseconds: 300 + (index * 50),
                                  ),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOutBack,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
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
                                            onTap: () =>
                                                onPhotoRemoved(photos[index]),
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
                                                    color: Colors.red
                                                        .withValues(alpha: 0.5),
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
                        ] else ...[
                          const SizedBox(height: 10),
                          if (isRequired && photos.isEmpty)
                            Text(
                              '${LocaleKeys.atLeast1PhotoRequired.tr()}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Return the card with selective interaction blocking
    return card;
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
                child: const Icon(
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
                  borderSide: const BorderSide(
                    color: AppColors.primaryRed,
                    width: 2,
                  ),
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
            isSignatureFromStorage: provider.isSignatureFromStorage,
            icon: Icons.person_outline,
            onDeleteSignature: () {
              provider.deleteSavedSignaturePermanently(context);
            },
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
    VoidCallback? onDeleteSignature,
    bool isSignatureFromStorage = false,
  }) {
    final bool hasSigned = signature != null;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
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
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: hasSigned
                        ? [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: hasSigned ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Badge
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
                      if (!hasSigned) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.gesture,
                              color: Colors.white38,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Saved Badge (compact)
                if (hasSigned && isSignatureFromStorage)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_done,
                          size: 10,
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          LocaleKeys.saved.tr(),
                          style: TextStyle(
                            color: Colors.green.shade300,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(width: 8),

                // Action Button
                if (hasSigned)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSignatureFromStorage && onDeleteSignature != null)
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: onDeleteSignature,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.orange,
                              size: 16,
                            ),
                            tooltip: LocaleKeys.deleteSaved.tr(),
                          ),
                        ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: onClear,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 16,
                          ),
                          tooltip: LocaleKeys.clear.tr(),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
              ],
            ),

            // Signature Preview (if signed)
            if (hasSigned) ...[
              const SizedBox(height: 12),
              Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.memory(signature, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActions(ProviderControl provider) {
    if (provider.isSubmittingOrUploading)
      return const Center(
        child: SizedBox.square(
          dimension: 40,
          child: CircularProgressIndicator(),
        ),
      );
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
              // isLoading: provider.isSubmittingOrUploading,
              text: LocaleKeys.previewPDF.tr(),
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
              // isLoading: provider.isSubmittingOrUploading,
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
    // ✅ Determine the message and icon based on current stage
    String message;
    IconData icon;

    switch (provider.currentUploadStage) {
      case UploadStage.uploadingPhotos:
        message = LocaleKeys.uploading_photos.tr();
        icon = Icons.photo_library_outlined;
        break;
      case UploadStage.uploadingPDF:
        message = LocaleKeys.uploadingPDF.tr();
        icon = Icons.picture_as_pdf_outlined;
        break;
      case UploadStage.submitting:
        message = LocaleKeys.submittingInspection.tr();
        icon = Icons.send_outlined;
        break;
      case UploadStage.compressingImages:
        message = LocaleKeys.compressing_images.tr();
        icon = Icons.compress_outlined;
        break;
      default:
        message = LocaleKeys.uploading.tr();
        icon = Icons.cloud_upload_outlined;
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
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
                      icon, // ✅ Dynamic icon based on stage
                      color: AppColors.primaryRed,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                message, // ✅ Dynamic message based on stage
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
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.pleaseWait.tr(),
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
    for (var category in provider.selectedTemplate!.categories) {
      // Skip disabled questions – they are treated as not applicable
      final isEnabled = _enabledCategories[category.categoryId] ?? true;
      if (!isEnabled) continue;

      final score = provider.getCategoryScore(category.categoryId);
      final photos = provider.getCategoryPhotos(category.categoryId);
      final notes = provider.getCategoryNotes(category.categoryId);

      if (score >= 3) {
        // Check what's missing
        final missingNotes = notes.trim().isEmpty;
        final missingPhotos = photos.isEmpty;

        if (missingNotes || missingPhotos) {
          final message = StringBuffer(
            LocaleKeys.categoryRequires.tr().replaceFirst(
              '{categoryName}',
              category.title,
            ),
          );
          if (missingNotes) message.write(' ${LocaleKeys.note.tr()}');
          if (missingNotes && missingPhotos)
            message.write(' ${LocaleKeys.and.tr()}');
          if (missingPhotos) message.write(' ${LocaleKeys.atLeast1Photo.tr()}');

          showSnakBarr(context, message.toString());
          return;
        }
      }
    }

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
              child: const Icon(
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

    // ✅ Check if user cancelled
    if (confirm != true) return;

    // ✅ Check if widget is still mounted before async operation
    if (!mounted) return;

    final success = await provider.submitInspection(context);

    // ✅ Check mounted after async operation
    if (!mounted) return;

    if (success) {
      // Stop auto-save timer and clear draft report after successful submission
      _autoSaveTimer?.cancel();
      await _clearDraftReport();

      showSnakBarr(context, LocaleKeys.inspection_submitted.tr());

      // ✅ Navigate properly based on source
      if (widget.from == AppConstants.details) {
        Navigator.of(context).pop(); // Pop detail screen
      }
      Navigator.of(context).pop(); // Pop current screen
    } else if (provider.errorMessage != null) {
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
                        const Icon(
                          Icons.gesture,
                          color: Colors.white38,
                          size: 16,
                        ),
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
