import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';

import '../core/constants/firebase_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String role; // "admin" | "inspector"
  final bool active;
  final String? region;
  final String createdAt;
  final String updatedAt;
  final String serviceAccount;
  List<String>? fcmTokens; // ✅ Changed from String? to List<String>?

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    this.region,
    this.fcmTokens, // ✅
    required this.serviceAccount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory to create from Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data[UserFields.name] ?? '',
      role: data[UserFields.role] ?? AppConstants.inspector,
      active: data[UserFields.active] ?? true,
      region: data[UserFields.region],
      serviceAccount: data[UserFields.serviceAccount],
      fcmTokens: (data[UserFields.fcmTokens] as List?)
          ?.map((e) => e.toString())
          .toList(), // ✅ Safe conversion
      createdAt: data[UserFields.createdAt].toString(),
      updatedAt: data[UserFields.updatedAt].toString(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map[UserFields.id] ?? '',
      name: map[UserFields.name] ?? '',
      role: map[UserFields.role] ?? AppConstants.inspector,
      active: map[UserFields.active] ?? true,
      region: map[UserFields.region],
      serviceAccount: map[UserFields.serviceAccount],
      fcmTokens: (map[UserFields.fcmTokens] as List?)
          ?.map((e) => e.toString())
          .toList(), // ✅
      createdAt: map[UserFields.createdAt],
      updatedAt: map[UserFields.updatedAt],
    );
  }

  /// Convert to Map (for Firestore or local storage)
  Map<String, dynamic> toMap() {
    return {
      UserFields.id: id,
      UserFields.name: name,
      UserFields.role: role,
      UserFields.active: active,
      UserFields.fcmTokens: fcmTokens, // ✅
      UserFields.region: region,
      UserFields.serviceAccount: serviceAccount,
      UserFields.createdAt: createdAt,
      UserFields.updatedAt: updatedAt,
    };
  }

  /// CopyWith method for updating fields
  UserModel copyWith({
    String? id,
    String? name,
    String? role,
    bool? active,
    String? region,
    String? createdAt,
    String? updatedAt,
    String? serviceAccount,
    List<String>? fcmTokens, // ✅ updated type
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      active: active ?? this.active,
      region: region ?? this.region,
      fcmTokens: fcmTokens ?? this.fcmTokens, // ✅
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceAccount: serviceAccount ?? this.serviceAccount,
    );
  }

  /// Convenience getters
  bool get isAdmin => role == AppConstants.admin;
  bool get isInspector => role == AppConstants.inspector;
}
