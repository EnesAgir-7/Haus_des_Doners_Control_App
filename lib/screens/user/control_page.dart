import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/providers/provider_branches.dart';
import 'package:haus_des_control/widgets/custom_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/branch_model.dart';
import '../../providers/provider_control.dart';
import '../../translations/locale_keys.g.dart';
import '../../widgets/app_button.dart';

class ControlPage extends StatefulWidget {
  final BranchModel? selectedBranch;

  const ControlPage({super.key, this.selectedBranch});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _overallNotesController = TextEditingController();
  BranchModel? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.selectedBranch;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedBranch != null) {
        final controlProvider = context.read<ProviderControl>();
        controlProvider.initialize(_selectedBranch!);
      }
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
        if (mounted) showSnakBarr(context, 'Maximum 4 photos allowed');
        return;
      }

      provider.addCategoryPhoto(category, file);
    } catch (e, st) {
      debugPrint('Error taking photo: $e\n$st');
      if (mounted) {
        showSnakBarr(context, "Error taking photo");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.lightBlack,
        title: Text(
          _selectedBranch?.name ?? 'Branch Inspection',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Consumer<ProviderControl>(
        builder: (context, provider, child) {
          if (_selectedBranch == null) {
            return _buildBranchSelector(context);
          }
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
                    _buildBranchInfoCard(),
                    SizedBox(height: 16),
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
                      const Text("No template linked to this branch"),

                    SizedBox(height: 16),
                    _buildOverallNotesSection(provider),

                    SizedBox(height: 16),

                    if (provider.totalScore > 0) _buildScorePreview(provider),

                    SizedBox(height: 24),
                    AppButton(
                      text: 'Submit Inspection',
                      icon: Icons.check_circle,
                      onPressed: provider.isFormValid
                          ? () => _submitInspection(provider)
                          : null,
                      backgroundColor: provider.isFormValid
                          ? AppColors.primaryRed
                          : Colors.grey,
                      height: 52,
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

  Widget _buildBranchSelector(BuildContext context) {
    return Consumer<ProviderBranches>(
      builder: (context, branchProvider, child) {
        if (branchProvider.branches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apartment, size: 80, color: Colors.white38),
                SizedBox(height: 16),
                Text(
                  'No branches available',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: branchProvider.branches.length,
          itemBuilder: (context, index) {
            final branch = branchProvider.branches[index];
            return Card(
              color: AppColors.lightBlack,
              child: ListTile(
                leading: Icon(Icons.apartment, color: AppColors.primaryRed),
                title: Text(branch.name, style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  branch.address,
                  style: TextStyle(color: Colors.white54),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54),
                onTap: () {
                  setState(() {
                    _selectedBranch = branch;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBranchInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primaryRed, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedBranch!.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _selectedBranch!.address,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

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
        color: AppColors.whiteWithOpacity(0.1),
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
                hintText: 'Add notes (optional)',
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
            'Overall Notes',
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
              hintText: 'Add general comments about this inspection...',
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

  Widget _buildScorePreview(ProviderControl provider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Score',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                provider.totalScore.toStringAsFixed(1),
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(Icons.star, size: 48, color: AppColors.primaryRed),
        ],
      ),
    );
  }

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
                'Uploading photos...',
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
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        title: Text(
          'Submit Inspection?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to submit this inspection? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Submit inspection
    final success = await provider.submitInspection();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inspection submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back after delay
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// class ControlPage extends StatefulWidget {
//   const ControlPage({super.key});

//   @override
//   State<ControlPage> createState() => _ControlPageState();
// }

// class _ControlPageState extends State<ControlPage> {
//   final List<Map<String, dynamic>> questions = [
//     {
//       'question': LocaleKeys.cleanliness_hygiene.tr(),
//       'rating': null,
//       'photos': <File>[],
//     },
//     {
//       'question': LocaleKeys.personnel_service.tr(),
//       'rating': null,
//       'photos': <File>[],
//     },
//     {
//       'question': LocaleKeys.product_quality.tr(),
//       'rating': null,
//       'photos': <File>[],
//     },
//     {
//       'question': LocaleKeys.store_organization.tr(),
//       'rating': null,
//       'photos': <File>[],
//     },
//   ];

//   final ImagePicker _picker = ImagePicker();

//   Future<void> _takePhoto(Map<String, dynamic> question) async {
//     try {
//       final XFile? photo = await _picker.pickImage(
//         source: ImageSource.camera,
//         preferredCameraDevice: CameraDevice.rear,
//       );

//       if (photo != null) {
//         setState(() {
//           List<File> photos = question['photos'] as List<File>;
//           photos.add(File(photo.path));
//         });
//       }
//     } catch (e) {
//       debugPrint('Error taking photo: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             ...questions.map((question) => _buildQuestionCard(question)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuestionCard(Map<String, dynamic> question) {
//     List<File> photos = question['photos'] as List<File>;
//     final List<String> emojis = ['😃', '🙂', '😐', '😞'];

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: AppColors.whiteWithOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(12),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   question['question'],
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: List.generate(4, (index) {
//                 final rating = index + 1;
//                 final bool isSelected = question['rating'] == rating;

//                 return GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       question['rating'] = rating;
//                     });
//                   },
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 300),
//                     width: isSelected ? 80 : 70,
//                     height: isSelected ? 80 : 70,
//                     decoration: BoxDecoration(
//                       color: isSelected
//                           ? AppColors.primaryRed
//                           : Colors.grey[300],
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withValues(alpha: 0.1),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           rating.toString(),
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: isSelected
//                                 ? AppColors.whiteWithOpacity(0.9)
//                                 : Colors.black,
//                           ),
//                         ),
//                         if (isSelected)
//                           AnimatedScale(
//                             scale: isSelected ? 1.3 : 1.0,
//                             duration: const Duration(milliseconds: 300),
//                             curve: Curves.elasticOut,
//                             child: Text(
//                               emojis[index],
//                               style: const TextStyle(fontSize: 24),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 );
//               }),
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.vertical(
//                 bottom: Radius.circular(12),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 AppButton(
//                   text: LocaleKeys.take_photo.tr(),
//                   icon: Icons.camera_alt,
//                   onPressed: () => _takePhoto(question),
//                   backgroundColor: AppColors.primaryRed,
//                   textStyle: TextStyle(color: AppColors.whiteWithOpacity(0.9)),
//                   height: 48,
//                 ),
//                 if (photos.isNotEmpty) ...[
//                   const SizedBox(height: 12),
//                   Container(
//                     height: 120,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: GridView.builder(
//                       scrollDirection: Axis.horizontal,
//                       gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 1,
//                             mainAxisSpacing: 8,
//                             childAspectRatio: 1,
//                           ),
//                       itemCount: photos.length,
//                       itemBuilder: (context, index) {
//                         return Stack(
//                           children: [
//                             Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(8),
//                                 image: DecorationImage(
//                                   image: FileImage(photos[index]),
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                             ),
//                             Positioned(
//                               top: 4,
//                               right: 4,
//                               child: InkWell(
//                                 onTap: () {
//                                   setState(() {
//                                     photos.removeAt(index);
//                                   });
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(2),
//                                   decoration: BoxDecoration(
//                                     color: AppColors.whiteWithOpacity(0.9),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(
//                                     Icons.close,
//                                     size: 16,
//                                     color: AppColors.primaryRed,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
