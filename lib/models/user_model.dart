import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "admin" | "inspector"
  final bool active;
  final String? region;
  // final String? assignedVehicleId;
  final String createdAt;
  final String updatedAt;
  final String? serviceAccount;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.region,
    this.serviceAccount,
    // this.assignedVehicleId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory to create from Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'inspector',
      active: data['active'] ?? true,
      region: data['region'],
      serviceAccount: data['serviceAccount'],
      // assignedVehicleId: data['assignedVehicleId'],
      createdAt: data['createdAt'].toString(),
      updatedAt: data['updatedAt'].toString(),
    );
  }

  /// Factory to create from local JSON/Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'inspector',
      active: map['active'] ?? true,
      region: map['region'],
      // assignedVehicleId: map['assignedVehicleId'],
      serviceAccount: map['serviceAccount'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  /// Convert to Map (for Firestore or local storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // include id for local storage
      'name': name,
      'email': email,
      'role': role,
      'active': active,
      'region': region,
      // 'assignedVehicleId': assignedVehicleId,
      "serviceAccount": serviceAccount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// CopyWith method for updating fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? active,
    String? region,
    String? assignedVehicleId,
    String? createdAt,
    String? updatedAt,
    String? serviceAccount,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      active: active ?? this.active,
      region: region ?? this.region,
      // assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceAccount: serviceAccount ?? this.serviceAccount,
    );
  }

  /// Convenience getters
  bool get isAdmin => role == 'admin';
  bool get isInspector => role == 'inspector';
}
