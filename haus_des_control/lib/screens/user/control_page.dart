import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/report_photo_provider.dart';
import '../../../widgets/camera_widget.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Consumer<ReportPhotoProvider>(
                builder: (context, photoProvider, child) {
                  final photos = photoProvider.photos;
                  if (photos.isEmpty) {
                    return Center(
                      child: ElevatedButton.icon(
                        onPressed: _openCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Fotoğraf Çek'),
                      ),
                    );
                  }
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: photos.length + 1, // +1 for camera button
                    itemBuilder: (context, index) {
                      if (index == photos.length) {
                        return InkWell(
                          onTap: _openCamera,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.camera_alt),
                          ),
                        );
                      }
                      
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
                              onTap: () => photoProvider.removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}