import 'package:cloud_firestore/cloud_firestore.dart';

import 'branch_model.dart';

class VehicleModel {
  final String id;
  final String plate;
  final String model;

  final AssignedInspector? assignedInspector;
  final int currentKm;
  final int maxKm;
  final int remainingKm;
  final int usagePercent;
  final DateTime lastServiceDate;
  final DateTime nextServiceDue;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleModel({
    required this.id,
    required this.plate,
    required this.model,
    required this.currentKm,

    this.assignedInspector,
    required this.maxKm,
    required this.remainingKm,
    required this.usagePercent,
    required this.lastServiceDate,
    required this.nextServiceDue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      plate: data['plate'] ?? '',
      model: data['model'] ?? '',
      assignedInspector: data['assignedInspector'] != null
          ? AssignedInspector(
              id: data['assignedInspector']['id'] ?? '',
              name: data['assignedInspector']['name'] ?? '',
            )
          : null,
      currentKm: data['currentKm'] ?? 0,
      maxKm: data['maxKm'] ?? 0,
      remainingKm: data['remainingKm'] ?? 0,
      usagePercent: data['usagePercent'] ?? 0,
      lastServiceDate: (data['lastServiceDate'] as Timestamp).toDate(),
      nextServiceDue: (data['nextServiceDue'] as Timestamp).toDate(),
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plate': plate,
      'model': model,
      'assignedInspector': {
        'id': assignedInspector?.id,
        'name': assignedInspector?.name,
      },
      'currentKm': currentKm,
      'maxKm': maxKm,
      'remainingKm': remainingKm,
      'usagePercent': usagePercent,
      'lastServiceDate': Timestamp.fromDate(lastServiceDate),
      'nextServiceDue': Timestamp.fromDate(nextServiceDue),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper to check if service is due soon
  bool get isServiceDueSoon {
    final daysUntilService = nextServiceDue.difference(DateTime.now()).inDays;
    return daysUntilService <= 5;
  }

  // Helper to get service due status
  String get serviceDueText {
    final daysUntilService = nextServiceDue.difference(DateTime.now()).inDays;
    if (daysUntilService < 0) return '${daysUntilService.abs()} gün gecikmiş';
    if (daysUntilService == 0) return 'Bugün';
    if (daysUntilService <= 5) return '$daysUntilService gün kaldı';
    return '${(daysUntilService / 7).floor()} hafta';
  }

  // Helper for KM progress color
  String get kmProgressColor {
    if (usagePercent >= 95) return 'red';
    if (usagePercent >= 70) return 'orange';
    return 'green';
  }
}
