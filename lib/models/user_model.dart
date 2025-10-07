import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "admin" | "inspector"
  final bool active;
  final String? region;
  final String? assignedVehicleId;
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.region,
    this.assignedVehicleId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'inspector',
      active: data['active'] ?? true,
      region: data['region'],
      assignedVehicleId: data['assignedVehicleId'],
      createdAt: data['createdAt'].toString(),
      updatedAt: data['updatedAt'].toString(),
    );
  }

  /// New factory to parse from JSON Map (for local storage)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'inspector',
      active: map['active'] ?? true,
      region: map['region'],
      assignedVehicleId: map['assignedVehicleId'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // include id for local storage
      'name': name,
      'email': email,
      'role': role,
      'active': active,
      'region': region,
      'assignedVehicleId': assignedVehicleId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isInspector => role == 'inspector';
}
