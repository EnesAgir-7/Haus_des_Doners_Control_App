import 'dart:io';
import 'package:flutter/material.dart';

/// Full-screen image viewer with zoom and pan capabilities
class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  final String? imageTitle;

  const ImagePreviewScreen({
    super.key,
    required this.imageFile,
    this.imageTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: imageTitle != null
            ? Text(imageTitle!, style: const TextStyle(color: Colors.white))
            : null,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(imageFile, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
