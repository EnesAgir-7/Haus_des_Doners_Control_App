import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import '../common_services/firebase_error_helper.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/firebase_constants.dart';
import '../translations/locale_keys.g.dart';
import 'branch_model.dart';

class VehicleModel {
  final String id;
  final String plate;
  final String model;
  final AssignedInspector? assignedInspector;
  int currentKm;
  final int maxKm;
  final int remainingKm;
  final int remainingPercent;
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
    required this.remainingPercent,
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
      plate: data[VehicleFields.plate] ?? '',
      model: data[VehicleFields.model] ?? '',
      currentKm: data[VehicleFields.currentKm] ?? 0,
      maxKm: data[VehicleFields.maxKm] ?? 0,
      remainingKm: data[VehicleFields.remainingKm] ?? 0,
      remainingPercent: data[VehicleFields.remainingPercent] ?? 100,

      // ✅ Use helper for all timestamps
      lastServiceDate: FirestoreHelpers.parseTimestamp(
        data[VehicleFields.lastServiceDate],
        fallback: DateTime.now().subtract(const Duration(days: 30)),
      ),
      nextServiceDue: FirestoreHelpers.parseTimestamp(
        data[VehicleFields.nextServiceDue],
        fallback: DateTime.now().add(const Duration(days: 30)),
      ),
      createdAt: FirestoreHelpers.parseTimestamp(data[VehicleFields.createdAt]),
      updatedAt: FirestoreHelpers.parseTimestamp(data[VehicleFields.updatedAt]),

      status: data[VehicleFields.status] ?? AppConstants.available,
      assignedInspector: data[VehicleFields.assignedInspector] != null
          ? AssignedInspector(
              id:
                  data[VehicleFields.assignedInspector][InspectorFields.id] ??
                  '',
              name:
                  data[VehicleFields.assignedInspector][InspectorFields.name] ??
                  '',
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      VehicleFields.plate: plate,
      VehicleFields.model: model,
      VehicleFields.assignedInspector: {
        InspectorFields.id: assignedInspector?.id,
        InspectorFields.name: assignedInspector?.name,
      },
      VehicleFields.currentKm: currentKm,
      VehicleFields.maxKm: maxKm,
      VehicleFields.remainingKm: remainingKm,
      VehicleFields.remainingPercent: remainingPercent,

      VehicleFields.lastServiceDate: Timestamp.fromDate(lastServiceDate),
      VehicleFields.nextServiceDue: Timestamp.fromDate(nextServiceDue),
      VehicleFields.status: status,
      VehicleFields.createdAt: Timestamp.fromDate(createdAt),
      VehicleFields.updatedAt: Timestamp.fromDate(updatedAt),
    };
  }

  VehicleModel copyWith({
    String? id,
    String? plate,
    String? model,
    AssignedInspector? assignedInspector,
    int? currentKm,
    int? maxKm,
    int? remainingPercent,

    int? remainingKm,
    DateTime? lastServiceDate,
    DateTime? nextServiceDue,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      model: model ?? this.model,
      assignedInspector: assignedInspector ?? this.assignedInspector,
      currentKm: currentKm ?? this.currentKm,
      remainingPercent: remainingPercent ?? this.remainingPercent,

      maxKm: maxKm ?? this.maxKm,
      remainingKm: remainingKm ?? this.remainingKm,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDue: nextServiceDue ?? this.nextServiceDue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isServiceDueSoon {
    final daysUntilService = nextServiceDue.difference(DateTime.now()).inDays;
    return daysUntilService <= 5;
  }

  // Helper to get service due status in English
  String get serviceDueText {
    final daysUntilService = nextServiceDue.difference(DateTime.now()).inDays;
    if (daysUntilService < 0)
      return "${daysUntilService.abs()} ${LocaleKeys.days_overdue.tr()}";
    if (daysUntilService == 0) return LocaleKeys.due_today.tr();
    if (daysUntilService <= 5)
      return "${daysUntilService} ${LocaleKeys.days_remaining.tr()}";
    return "${(daysUntilService / 7).floor()} ${LocaleKeys.weeks_remaining.tr()}";
  }

  // Helper for KM progress color
  String get kmProgressColor {
    if (remainingPercent >= 95) return 'red';
    if (remainingPercent >= 70) return 'orange';
    return 'green';
  }
}
