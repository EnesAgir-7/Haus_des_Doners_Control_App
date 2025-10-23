import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';

import '../core/constants/firebase_constants.dart';
import 'route_model.dart';

class BranchModel {
  final String id;
  final String name;
  final String address;
  final String templateId;
  final String? region;
  final GeoPoint gps;
  final String contactName;
  final String contactPhone;
  final RouteStopModel? stop;
  AssignedInspector? assignedInspector;
  final DateTime? lastInspectionDate;
  final String? lastInspectionScore;
  final int totalInspections;
  final double averageScore;
  final String status;
  final List<String>? last12MonthsScores;

  final DateTime createdAt;
  final DateTime updatedAt;

  BranchModel({
    required this.id,
    required this.templateId,
    required this.name,
    required this.address,
    this.region,
    required this.gps,
    required this.contactName,
    required this.contactPhone,
    this.assignedInspector,
    this.last12MonthsScores,
    this.lastInspectionDate,
    this.lastInspectionScore,
    required this.totalInspections,
    required this.averageScore,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.stop,
  });

  factory BranchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BranchModel(
      id: doc.id,
      name: data[BranchFields.name] ?? '',
      address: data[BranchFields.address] ?? '',
      templateId: data[BranchFields.templateId] ?? '',
      region: data[BranchFields.region],
      gps: data[BranchFields.gps] as GeoPoint,
      contactName: data[BranchFields.contactName] ?? '',
      contactPhone: data[BranchFields.contactPhone] ?? '',
      assignedInspector: data[BranchFields.assignedInspector] != null
          ? AssignedInspector(
              id:
                  data[BranchFields.assignedInspector][InspectorFields.id] ??
                  '',
              name:
                  data[BranchFields.assignedInspector][InspectorFields.name] ??
                  '',
            )
          : null,
      lastInspectionDate: data[BranchFields.lastInspectionDate] != null
          ? (data[BranchFields.lastInspectionDate] as Timestamp).toDate()
          : null,
      lastInspectionScore: data[BranchFields.lastInspectionScore],
      totalInspections: data[BranchFields.totalInspections] ?? 0,
      averageScore: (data[BranchFields.averageScore] ?? 0.0).toDouble(),
      status: data[BranchFields.status] ?? AppConstants.active,
      createdAt: data[BranchFields.createdAt] != null
          ? (data[BranchFields.createdAt] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data[BranchFields.updatedAt] != null
          ? (data[BranchFields.updatedAt] as Timestamp).toDate()
          : DateTime.now(),
      stop: data[BranchFields.stop] != null
          ? RouteStopModel.fromMap(
              Map<String, dynamic>.from(data[BranchFields.stop]),
            )
          : null,
last12MonthsScores: data[BranchFields.last12MonthsScores] != null
          ? List<String>.from(
              (data[BranchFields.last12MonthsScores] as List<dynamic>).map(
                (e) => e.toString(),
              ),
            )
          : List.filled(12, '0'),

    );
  }

  BranchModel copyWith({
    String? id,
    String? name,
    String? address,
    String? templateId,
    String? region,
    GeoPoint? gps,
    String? contactName,
    String? contactPhone,
    AssignedInspector? assignedInspector,
    DateTime? lastInspectionDate,
    String? lastInspectionScore,
    int? totalInspections,
    double? averageScore,
    String? status,
    DateTime? createdAt,
    List<String>? last12MonthsScores,

    DateTime? updatedAt,
    RouteStopModel? stop,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      templateId: templateId ?? this.templateId,
      region: region ?? this.region,
      gps: gps ?? this.gps,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      assignedInspector: assignedInspector ?? this.assignedInspector,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      lastInspectionScore: lastInspectionScore ?? this.lastInspectionScore,
      totalInspections: totalInspections ?? this.totalInspections,
      averageScore: averageScore ?? this.averageScore,
      status: status ?? this.status,
      last12MonthsScores: last12MonthsScores ?? this.last12MonthsScores,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stop: stop ?? this.stop,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      BranchFields.name: name,
      BranchFields.address: address,
      BranchFields.region: region,
      BranchFields.gps: gps,
      BranchFields.contactName: contactName,
      BranchFields.contactPhone: contactPhone,
      BranchFields.templateId: templateId,
      BranchFields.assignedInspector: {
        InspectorFields.id: assignedInspector?.id,
        InspectorFields.name: assignedInspector?.name,
      },
      BranchFields.lastInspectionDate: lastInspectionDate != null
          ? Timestamp.fromDate(lastInspectionDate!)
          : null,
      BranchFields.lastInspectionScore: lastInspectionScore,
      BranchFields.last12MonthsScores: last12MonthsScores,
      BranchFields.totalInspections: totalInspections,
      BranchFields.averageScore: averageScore,
      BranchFields.status: status,
      BranchFields.createdAt: Timestamp.fromDate(createdAt),
      BranchFields.updatedAt: Timestamp.fromDate(updatedAt),
      BranchFields.stop: stop?.toMap(),
    };
  }

  // Helper: Days since last inspection
  int? get daysSinceLastInspection {
    if (lastInspectionDate == null) return null;
    return DateTime.now().difference(lastInspectionDate!).inDays;
  }

  int? get daysUntilNextInspection {
    if (stop?.timeSlot == null || stop!.timeSlot.isEmpty) return null;
    try {
      final nextDate = DateTime.parse(stop!.timeSlot);
      final difference = nextDate.difference(DateTime.now());
      return difference.inDays;
    } catch (e) {
      // Parsing failed
      return null;
    }
  }

  // Helper: Last inspection text (Turkish)
  String get lastInspectionText {
    if (lastInspectionDate == null) return 'Not inspected yet';
    final days = daysSinceLastInspection!;
    if (days == 0) return 'Inspected today';
    if (days == 1) return 'Inspected yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) return '${(days / 7).floor()} weeks ago';
    return '${(days / 30).floor()} months ago';
  }

  bool get isNextInspectionToday {
    return stop?.timeSlot != null &&
        stop!.timeSlot.isNotEmpty &&
        stop?.timeSlot == DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}

class AssignedInspector {
  final String id;
  final String name;

  AssignedInspector({required this.id, required this.name});

  factory AssignedInspector.fromMap(Map<String, dynamic> map) {
    return AssignedInspector(
      id: map[InspectorFields.id] ?? '',
      name: map[InspectorFields.name] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {InspectorFields.id: id, InspectorFields.name: name};
  }
}
