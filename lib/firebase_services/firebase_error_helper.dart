import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseSafeRunner {
  /// Runs an async Firebase operation safely
  /// and returns either the result or null on error.
  static Future<T?> run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e, st) {
      _log("FirebaseException: ${_mapFirebaseError(e)}", st);
      return null;
    } catch (e, st) {
      _log("Generic error: $e", st);
      return null;
    }
  }

  /// Maps Firebase error codes to user-friendly messages
  static String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return "You don’t have permission to access this data.";
      case 'unavailable':
        return "Service is currently unavailable. Try again later.";
      case 'not-found':
        return "The requested document was not found.";
      case 'cancelled':
        return "The operation was cancelled.";
      case 'deadline-exceeded':
        return "The operation took too long. Please retry.";
      case 'unauthenticated':
        return "You must be logged in to perform this action.";
      default:
        return "Unexpected Firestore error: ${e.message}";
    }
  }

  static void _log(String message, StackTrace st) {
    debugPrint("❌ FirebaseSafeRunner: $message");
    debugPrint(st.toString());
  }
}
