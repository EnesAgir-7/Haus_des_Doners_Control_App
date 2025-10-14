import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

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
    final stopsData = data['stops'] as List<dynamic>;

    return RouteModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      inspectorId: data['inspectorId'] ?? '',
      inspectorName: data['inspectorName'] ?? '',
      stops: stopsData
          .map((stop) => RouteStopModel.fromMap(stop as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'stops': stops.map((stop) => stop.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
  final String? inspectionId;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? expiryDate; //
  final int order;
  final double? inspectionScore; //

  RouteStopModel({
    required this.timeSlot,
    required this.branchId,
    required this.branchName,
    required this.branchTemplateId,
    required this.status,
    this.inspectionId,
    required this.order,
    this.createdAt,
    this.completedAt,
    this.expiryDate, //
    this.inspectionScore, //
  });

  factory RouteStopModel.fromMap(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value.toString());
    }

    return RouteStopModel(
      timeSlot: data['timeSlot'] ?? '',
      branchId: data['branchId'] ?? '',
      branchName: data['branchName'] ?? '',
      branchTemplateId: data["branchTemplateId"] ?? '',
      status: data['status'] ?? 'pending',
      inspectionId: data['inspectionId'],
      order: data['order'] ?? 0,
      createdAt: parseDate(data["createdAt"]),
      completedAt: parseDate(data["completedAt"]),
      expiryDate: parseDate(data["expiryDate"]), //
      inspectionScore: data['inspectionScore'] != null
          ? double.tryParse(data['inspectionScore'].toString())
          : null, //
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeSlot': timeSlot,
      'branchId': branchId,
      'branchName': branchName,
      'branchTemplateId': branchTemplateId,
      'status': status,
      'inspectionId': inspectionId,
      'order': order,
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(), //
      'inspectionScore': inspectionScore?.toDouble(), //
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
    DateTime? expiryDate, //
    double? inspectionScore, //
  }) {
    return RouteStopModel(
      timeSlot: timeSlot ?? this.timeSlot,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      branchTemplateId: branchTemplateId ?? this.branchTemplateId,
      status: status ?? this.status,
      inspectionId: inspectionId ?? this.inspectionId,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiryDate: expiryDate ?? this.expiryDate, //
      inspectionScore: inspectionScore ?? this.inspectionScore, //
    );
  }

  bool get isCompleted => status == AppConstants.completed;
  bool get isPending => status == AppConstants.pending;
  bool get isCurrent => status == AppConstants.current;

  /// Helper: check if stop is expired
  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);
}
