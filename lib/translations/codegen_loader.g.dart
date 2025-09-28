// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes, avoid_renaming_method_parameters, constant_identifier_names

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    return Future.value(mapLocales[locale.toString()]);
  }

  static const Map<String,dynamic> _de = {
  "panel": "Panel",
  "subsidiaries": "Şubeler",
  "fleet": "Kontrol",
  "route": "Rota",
  "file": "Filo",
  "tasks": "Görevler",
  "change_language": "Sprache ändern",
  "select_language": "Sprache auswählen",
  "take_photo": "Fotoğraf Çek",
  "terms_and_privacy": "Temizlik & Hijyen",
  "personal_and_service": "Personel & Hizmet",
  "product_quality": "Ürün Kalitesi",
  "store_rating": "Mağaza Düzeni",
  "control": "Kontrolle",
  "cancel": "Abbrechen"
};
static const Map<String,dynamic> _en = {
  "panel": "Panel",
  "subsidiaries": "Subsidiaries",
  "fleet": "Fleet",
  "route": "Route",
  "file": "File",
  "tasks": "Tasks",
  "change_language": "Change Language",
  "select_language": "Select Language",
  "take_photo": "Take Photo",
  "terms_and_privacy": "Cleanliness & Hygiene",
  "personal_and_service": "Staff & Service",
  "product_quality": "Product Quality",
  "store_rating": "Store Layout",
  "control": "Control",
  "cancel": "Cancel"
};
static const Map<String,dynamic> _tr = {
  "panel": "Panel",
  "subsidiaries": "Şubeler",
  "fleet": "Filo",
  "route": "Rota",
  "file": "Dosya",
  "tasks": "Görevler",
  "change_language": "Dili Değiştir",
  "select_language": "Dil Seçin",
  "take_photo": "Fotoğraf Çek",
  "terms_and_privacy": "Temizlik & Hijyen",
  "personal_and_service": "Personel & Hizmet",
  "product_quality": "Ürün Kalitesi",
  "store_rating": "Mağaza Düzeni",
  "control": "Kontrol",
  "cancel": "İptal"
};
static const Map<String, Map<String,dynamic>> mapLocales = {"de": _de, "en": _en, "tr": _tr};
}
