import 'package:flutter/material.dart';
import 'dart:io';

class ProviderReportPhoto extends ChangeNotifier {
  List<File> _photos = [];
  List<File> get photos => _photos;

  void addPhoto(File photo) {
    _photos.add(photo);
    notifyListeners();
  }

  void removePhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      _photos.removeAt(index);
      notifyListeners();
    }
  }

  void clearPhotos() {
    _photos.clear();
    notifyListeners();
  }
}