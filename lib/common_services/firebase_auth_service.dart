import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      throw e.message ?? 'An error occurred';
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
      throw Exception(e.message ?? 'Auth creation failed');
    }
  }

  Future<void> deleteInspectorAccount({required String inspectorUid}) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteInspector',
      );

      final result = await callable.call({'uid': inspectorUid});

      if (result.data['success'] != true) {
        // Fail silently with message
        throw Exception(result.data['message'] ?? 'Failed to delete inspector');
      }
    } on FirebaseFunctionsException catch (e) {
      // Convert known codes into friendly messages
      String errorMessage = switch (e.code) {
        'failed-precondition' => e.message ?? 'Inspector has active routes',
        'permission-denied' => e.message ?? 'Permission denied',
        'unauthenticated' => 'You must be logged in',
        'not-found' => 'Inspector not found',
        _ => 'Failed to delete: ${e.message}',
      };

      throw Exception(errorMessage); // will be shown in UI
    } catch (e) {
      // Catch all other errors
      throw Exception('Failed to delete inspector: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
