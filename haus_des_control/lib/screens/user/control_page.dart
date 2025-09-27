import 'package:flutter/material.dart';
import 'package:haus_des_control/core/theme/app_colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  // List of questions for store evaluation with photos
  final List<Map<String, dynamic>> questions = [
    {'question': 'Temizlik & Hijyen', 'rating': null, 'photos': <File>[]},      // Cleanliness & Hygiene
    {'question': 'Personel & Hizmet', 'rating': null, 'photos': <File>[]},      // Personnel & Service
    {'question': 'Ürün Kalitesi', 'rating': null, 'photos': <File>[]},          // Product Quality
    {'question': 'Mağaza Düzeni', 'rating': null, 'photos': <File>[]},          // Store Organization
  ];

  final ImagePicker _picker = ImagePicker();

  // Function to handle taking photos for a specific question
  Future<void> _takePhoto(Map<String, dynamic> question) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (photo != null) {
        setState(() {
          List<File> photos = question['photos'] as List<File>;
          photos.add(File(photo.path));
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Questions and Ratings
            ...questions.map((question) => _buildQuestionCard(question)),
          ],
        ),
      ),
    );
  }


  // Builds a single question card with rating options and photo section
  Widget _buildQuestionCard(Map<String, dynamic> question) {
    List<File> photos = question['photos'] as List<File>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.whiteWithOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Question header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  question['question'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Rating options
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final rating = index + 1;
                return InkWell(
                  onTap: () {
                    setState(() {
                      question['rating'] = rating;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: question['rating'] == rating
                          ? AppColors.primaryRed
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        rating.toString(),
                        style: TextStyle( 
                          color: question['rating'] == rating
                              ? AppColors.whiteWithOpacity(0.9)
                              : Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Photo section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo capture button
                ElevatedButton.icon(
                  onPressed: () => _takePhoto(question),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Fotoğraf Çek'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: AppColors.whiteWithOpacity(0.9),
                  ),
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  // Photo grid
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(photos[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    photos.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteWithOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}