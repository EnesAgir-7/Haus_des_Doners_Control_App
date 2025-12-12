import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:easy_localization/easy_localization.dart';

import '../translations/locale_keys.g.dart';

class FirebaseAuthHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign In
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? LocaleKeys.error_occurred.tr();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create user
  Future<UserCredential> createUserWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? LocaleKeys.auth_creation_failed.tr());
    }
  }

  Future<void> deleteInspectorAccount({required String inspectorUid}) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteInspector',
      );

      final result = await callable.call({'uid': inspectorUid});

      if (result.data['success'] != true) {
        throw Exception(
          result.data['message'] ?? LocaleKeys.failed_to_delete_inspector.tr(),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      String errorMessage = switch (e.code) {
        'failed-precondition' =>
          e.message ?? LocaleKeys.inspector_has_active_routes.tr(),
        'permission-denied' => e.message ?? LocaleKeys.permission_denied.tr(),
        'unauthenticated' => LocaleKeys.must_be_logged_in.tr(),
        'not-found' => LocaleKeys.inspector_not_found.tr(),
        _ => '${LocaleKeys.failed_to_delete.tr()}: ${e.message}',
      };

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('${LocaleKeys.failed_to_delete_inspector.tr()}: $e');
    }
  }

  Future<void> updateInspectorPassword({
    required String inspectorUid,
    required String newPassword,
  }) async {
    console(inspectorUid);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'updatePassword',
      );

      final result = await callable.call({
        'uid': inspectorUid,
        'newPassword': newPassword,
      });

      if (result.data['success'] != true) {
        throw Exception(
          result.data['message'] ?? LocaleKeys.failed_to_update_password.tr(),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? LocaleKeys.failed_to_update_password.tr());
    }
  }

  // New: delete a normal user (admin or branch) using the callable cloud function `deleteUser`
  Future<void> deleteUserAccount({required String userUid}) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deleteUser');

      final result = await callable.call({'uid': userUid});

      if (result.data['success'] != true) {
        throw Exception(
          result.data['message'] ?? LocaleKeys.failed_to_delete.tr(),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? LocaleKeys.failed_to_delete.tr());
    } catch (e) {
      throw Exception('${LocaleKeys.failed_to_delete.tr()}: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
