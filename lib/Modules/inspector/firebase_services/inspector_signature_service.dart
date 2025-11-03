import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/firebase_constants.dart';

class SignatureStorageService {
  // User-specific keys using global loggedInUser?
  String get _signatureKey => 'inspector_signature_${loggedInUser?.id}';
  String get _signatureTimestampKey =>
      'inspector_signature_timestamp_${loggedInUser?.id}';

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
      print('Error saving signature for user ${loggedInUser?.id}: $e');
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
      print('Error loading signature for user ${loggedInUser?.id}: $e');
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
      print('Error deleting signature for user ${loggedInUser?.id}: $e');
      return false;
    }
  }

  // Static method to delete all signatures (useful for cleanup/logout)
  static Future<bool> deleteAllSignatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith('inspector_signature_')) {
          await prefs.remove(key);
        }
      }

      return true;
    } catch (e) {
      print('Error deleting all signatures: $e');
      return false;
    }
  }
}
