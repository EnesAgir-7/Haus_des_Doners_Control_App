import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class SignatureStorageService {
  static const String _signatureKey = 'inspector_signature';
  static const String _signatureTimestampKey = 'inspector_signature_timestamp';

  // Save signature as base64 string

  Future<bool> saveSignature(Uint8List signatureBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final base64Signature = base64Encode(signatureBytes);
      final timestamp = DateTime.now().toIso8601String();

      await prefs.setString(_signatureKey, base64Signature);
      await prefs.setString(_signatureTimestampKey, timestamp);

      return true;
    } catch (e) {
      print('Error saving signature: $e');
      return false;
    }
  }

  // Load signature from storage
  Future<Uint8List?> loadSignature() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final base64Signature = prefs.getString(_signatureKey);

      if (base64Signature == null) return null;

      return base64Decode(base64Signature);
    } catch (e) {
      print('Error loading signature: $e');
      return null;
    }
  }

  // Check if signature exists
  Future<bool> hasSignature() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_signatureKey);
    } catch (e) {
      return false;
    }
  }

  // Get signature timestamp
  Future<DateTime?> getSignatureTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_signatureTimestampKey);

      if (timestamp == null) return null;

      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  // Delete saved signature
  Future<bool> deleteSignature() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_signatureKey);
      await prefs.remove(_signatureTimestampKey);
      return true;
    } catch (e) {
      print('Error deleting signature: $e');
      return false;
    }
  }
}
