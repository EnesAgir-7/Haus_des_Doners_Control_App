import 'package:cloud_firestore/cloud_firestore.dart';

import '../common_services/firebase_error_helper.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/firebase_constants.dart';

/// 🔹 Main Route Model (represents an inspector’s route for the day)
class RouteModel {
  final String id;
  final DateTime date;
  final String inspectorId;
  final String inspectorName;
  final List<RouteStopModel> stops;
  final DateTime createdAt;
  final DateTime updatedAt;

  RouteModel({
    required this.id,
    required this.date,
    required this.inspectorId,
    required this.inspectorName,
    required this.stops,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final stopsData = data[RouteFields.stops] as List<dynamic>? ?? [];

    return RouteModel(
      id: doc.id,
      // ✅ FIXED: Using FirestoreHelpers
      date: FirestoreHelpers.parseTimestamp(data[RouteFields.date]),
      inspectorId: data[RouteFields.inspectorId] ?? '',
      inspectorName: data[RouteFields.inspectorName] ?? '',
      stops: stopsData
          .map((stop) => RouteStopModel.fromMap(stop as Map<String, dynamic>))
          .toList(),
      // ✅ FIXED: Using FirestoreHelpers
      createdAt: FirestoreHelpers.parseTimestamp(data[RouteFields.createdAt]),
      updatedAt: FirestoreHelpers.parseTimestamp(data[RouteFields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      RouteFields.id: id,
      RouteFields.date: Timestamp.fromDate(date),
      RouteFields.inspectorId: inspectorId,
      RouteFields.inspectorName: inspectorName,
      RouteFields.stops: stops.map((stop) => stop.toMap()).toList(),
      RouteFields.createdAt: Timestamp.fromDate(createdAt),
      RouteFields.updatedAt: Timestamp.fromDate(updatedAt),
    };
  }

  int get completedStopsCount => stops.where((s) => s.isCompleted).length;
  int get totalStops => stops.length;

  double get completionPercent =>
      totalStops > 0 ? (completedStopsCount / totalStops) * 100 : 0;
}

class RouteStopModel {
  final String timeSlot;
  final String branchId;
  final String branchName;
  final String branchTemplateId;
  final String status; // "completed" | "pending" | "current"
  final DateTime? createdAt;
  final DateTime? completedAt;
  final Timestamp? expiryDate;
  final int order;
  final String? inspectionScore;
  final String? branchAddress;

  RouteStopModel({
    required this.timeSlot,
    required this.branchId,
    required this.branchName,
    required this.branchTemplateId,
    required this.status,
    required this.order,
    this.createdAt,
    this.completedAt,
    this.expiryDate,
    this.inspectionScore,
    this.branchAddress,
  });

  factory RouteStopModel.fromMap(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value.toString());
    }

    return RouteStopModel(
      timeSlot: data[RouteStopFields.timeSlot] ?? '',
      branchId: data[RouteStopFields.branchId] ?? '',
      branchName: data[RouteStopFields.branchName] ?? '',
      branchTemplateId: data[RouteStopFields.branchTemplateId] ?? '',
      status: data[RouteStopFields.status] ?? AppConstants.pending,
      order: data[RouteStopFields.order] ?? 0,
      createdAt: parseDate(data[RouteStopFields.createdAt]),
      completedAt: parseDate(data[RouteStopFields.completedAt]),
      expiryDate: data[RouteStopFields.expiryDate],
      inspectionScore: data[RouteStopFields.inspectionScore] != null
          ? data[RouteStopFields.inspectionScore].toString()
          : null,
      branchAddress: data[RouteStopFields.branchAddress],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      RouteStopFields.timeSlot: timeSlot,
      RouteStopFields.branchId: branchId,
      RouteStopFields.branchName: branchName,
      RouteStopFields.branchTemplateId: branchTemplateId,
      RouteStopFields.status: status,
      RouteStopFields.order: order,
      RouteStopFields.createdAt: createdAt?.toIso8601String(),
      RouteStopFields.completedAt: completedAt?.toIso8601String(),
      RouteStopFields.expiryDate: expiryDate,
      RouteStopFields.inspectionScore: inspectionScore,
      RouteStopFields.branchAddress: branchAddress,
    };
  }

  RouteStopModel copyWith({
    String? timeSlot,
    String? branchId,
    String? branchName,
    String? branchTemplateId,
    String? status,
    String? inspectionId,
    int? order,
    DateTime? createdAt,
    DateTime? completedAt,
    Timestamp? expiryDate,
    String? inspectionScore,
    String? branchAddress,
  }) {
    return RouteStopModel(
      timeSlot: timeSlot ?? this.timeSlot,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      branchTemplateId: branchTemplateId ?? this.branchTemplateId,
      status: status ?? this.status,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      inspectionScore: inspectionScore ?? this.inspectionScore,
      branchAddress: branchAddress ?? this.branchAddress,
    );
  }

  /// 🔹 Helper Computed Getters
  bool get isCompleted => status == AppConstants.completed;
  bool get isPending => status == AppConstants.pending;
  bool get isCurrent => status == AppConstants.current;

  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!.toDate());
}
