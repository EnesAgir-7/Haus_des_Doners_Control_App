import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';

import '../translations/locale_keys.g.dart';

class FirebaseSafeRunner {
  /// Runs an async Firebase operation safely
  /// and returns either the result or null on error.
  static Future<T?> run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e, st) {
      _log(
        "${LocaleKeys.firebase_exception.tr()}: ${_mapFirebaseError(e)}",
        st,
      );
      return null;
    } catch (e, st) {
      _log("${LocaleKeys.generic_error.tr()}: $e", st);
      return null;
    }
  }

  /// Maps Firebase error codes to user-friendly messages
  static String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return LocaleKeys.no_permission_access.tr();
      case 'unavailable':
        return LocaleKeys.service_unavailable.tr();
      case 'not-found':
        return LocaleKeys.document_not_found.tr();
      case 'cancelled':
        return LocaleKeys.operation_cancelled.tr();
      case 'deadline-exceeded':
        return LocaleKeys.operation_too_long.tr();
      case 'unauthenticated':
        return LocaleKeys.must_be_logged_in_action.tr();
      default:
        return "${LocaleKeys.unexpected_firestore_error.tr()}: ${e.message}";
    }
  }

  static void _log(String message, StackTrace st) {
    debugPrint("❌ FirebaseSafeRunner: $message");
    debugPrint(st.toString());
  }
}

class FirestoreHelpers {
  /// ✅ Safely parse Firestore Timestamp, handling null from serverTimestamp()
  static DateTime parseTimestamp(dynamic timestamp, {DateTime? fallback}) {
    if (timestamp == null) {
      return fallback ?? DateTime.now();
    }

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    // If it's already a DateTime (shouldn't happen but defensive)
    if (timestamp is DateTime) {
      return timestamp;
    }

    // Last resort fallback
    return fallback ?? DateTime.now();
  }

  /// ✅ Safely parse nullable Timestamp
  static DateTime? parseTimestampNullable(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }
}
