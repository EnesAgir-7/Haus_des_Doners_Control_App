import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = Collections.users;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _db.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Stream user by ID (real-time updates)
  Stream<UserModel?> streamUserById(String userId) {
    return _db.collection(_collection).doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // Get all active inspectors
  Future<List<UserModel>> getActiveInspectors() async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('role', isEqualTo: AppConstants.inspector)
          .where('active', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting inspectors: $e');
      return [];
    }
  }

  // Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _db.collection(_collection).get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection(_collection).doc(userId).update(data);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Create user
  Future<void> createUser(String userId, UserModel user) async {
    try {
      await _db.collection(_collection).doc(userId).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }
}
