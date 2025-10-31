import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:haus_des_control/helpers/app_helpers.dart';

import '../core/constants/firebase_constants.dart';
import 'route_model.dart';

// Add these helper classes at the top
class ContactPerson {
  final String name;
  final String phone;

  ContactPerson({required this.name, required this.phone});

  factory ContactPerson.fromMap(Map<String, dynamic> map) {
    return ContactPerson(name: map['name'] ?? '', phone: map['phone'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone};
  }
}

class OpeningHours {
  final String openingTime;
  final String closingTime;

  OpeningHours({required this.openingTime, required this.closingTime});

  factory OpeningHours.fromMap(Map<String, dynamic> map) {
    return OpeningHours(
      openingTime: map['openingTime'] ?? '',
      closingTime: map['closingTime'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'openingTime': openingTime, 'closingTime': closingTime};
  }
}

class BranchModel {
  final String id;
  final String name;
  final String address;
  final String? region;
  String templateId;
  String templateName;
  final GeoPoint gps;
  final String contactName;
  final String contactPhone;
  final RouteStopModel? stop;
  AssignedInspector? assignedInspector;
  final DateTime? lastInspectionDate;
  final String? lastInspectionScore;
  final int totalInspections;
  final String averageScore;
  final String status;
  final List<String>? last12MonthsScores;
  final DateTime createdAt;
  final DateTime updatedAt;

  // New fields
  final OpeningHours? openingHours;
  final List<String>? openingDays;
  final List<ContactPerson>? suppliers;
  final DateTime? openingDay;
  final String? donerPrices;
  final String? software;
  final String? shopInformation;
  final List<ContactPerson>? branchOwners;
  final List<ContactPerson>? branchManagers;
  final String? branchEmail;

  BranchModel({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.name,
    required this.address,
    required this.region,
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
    // New fields
    this.suppliers,
    this.openingHours,
    this.openingDays,
    this.openingDay,
    this.donerPrices,
    this.software,
    this.shopInformation,
    this.branchOwners,
    this.branchManagers,
    this.branchEmail,
  });

  factory BranchModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return BranchModel(
      id: id ?? '',
      name: data[BranchFields.name] ?? '',
      address: data[BranchFields.address] ?? '',
      region: data[BranchFields.region] ?? '',
      templateId: data[BranchFields.templateId] ?? '',
      templateName: data[BranchFields.templateName] ?? '',
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
          ? (data[BranchFields.lastInspectionDate] is Timestamp
                ? (data[BranchFields.lastInspectionDate] as Timestamp).toDate()
                : DateTime.tryParse(
                        data[BranchFields.lastInspectionDate].toString(),
                      ) ??
                      DateTime.now())
          : null,
      lastInspectionScore: data[BranchFields.lastInspectionScore],
      totalInspections: data[BranchFields.totalInspections] ?? 0,
      averageScore: (data[BranchFields.averageScore] ?? "0/0"),
      status: data[BranchFields.status] ?? AppConstants.active,
      createdAt: data[BranchFields.createdAt] != null
          ? (data[BranchFields.createdAt] is Timestamp
                ? (data[BranchFields.createdAt] as Timestamp).toDate()
                : DateTime.tryParse(data[BranchFields.createdAt].toString()) ??
                      DateTime.now())
          : DateTime.now(),
      updatedAt: data[BranchFields.updatedAt] != null
          ? (data[BranchFields.updatedAt] is Timestamp
                ? (data[BranchFields.updatedAt] as Timestamp).toDate()
                : DateTime.tryParse(data[BranchFields.updatedAt].toString()) ??
                      DateTime.now())
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
      // New fields
      openingHours: data['openingHours'] != null
          ? OpeningHours.fromMap(
              Map<String, dynamic>.from(data['openingHours']),
            )
          : null,
      openingDays: data['openingDays'] != null
          ? List<String>.from(data['openingDays'])
          : null,
      suppliers: data['suppliers'] != null
          ? (data['suppliers'] as List)
                .map((e) => ContactPerson.fromMap(Map<String, dynamic>.from(e)))
                .toList()
          : null,
      openingDay: data['openingDay'] != null
          ? (data['openingDay'] is Timestamp
                ? (data['openingDay'] as Timestamp).toDate()
                : DateTime.tryParse(data['openingDay'].toString()))
          : null,
      donerPrices: data['donerPrices'],
      software: data['software'],
      shopInformation: data['shopInformation'],
      branchOwners: data['branchOwners'] != null
          ? (data['branchOwners'] as List)
                .map((e) => ContactPerson.fromMap(Map<String, dynamic>.from(e)))
                .toList()
          : null,
      branchManagers: data['branchManagers'] != null
          ? (data['branchManagers'] as List)
                .map((e) => ContactPerson.fromMap(Map<String, dynamic>.from(e)))
                .toList()
          : null,
      branchEmail: data['branchEmail'],
    );
  }

  factory BranchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BranchModel.fromMap(data, id: doc.id);
  }

  BranchModel copyWith({
    String? id,
    String? name,
    String? address,
    String? region,
    String? templateId,
    String? templateName,
    GeoPoint? gps,
    String? contactName,
    String? contactPhone,
    AssignedInspector? assignedInspector,
    DateTime? lastInspectionDate,
    String? lastInspectionScore,
    int? totalInspections,
    String? averageScore,
    String? status,
    DateTime? createdAt,
    List<String>? last12MonthsScores,
    DateTime? updatedAt,
    RouteStopModel? stop,
    OpeningHours? openingHours,
    List<String>? openingDays,
    List<ContactPerson>? suppliers,
    DateTime? openingDay,
    String? donerPrices,
    String? software,
    String? shopInformation,
    List<ContactPerson>? branchOwners,
    List<ContactPerson>? branchManagers,
    String? branchEmail,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      region: region ?? this.region,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
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
      openingHours: openingHours ?? this.openingHours,
      openingDays: openingDays ?? this.openingDays,
      suppliers: suppliers ?? this.suppliers,
      openingDay: openingDay ?? this.openingDay,
      donerPrices: donerPrices ?? this.donerPrices,
      software: software ?? this.software,
      shopInformation: shopInformation ?? this.shopInformation,
      branchOwners: branchOwners ?? this.branchOwners,
      branchManagers: branchManagers ?? this.branchManagers,
      branchEmail: branchEmail ?? this.branchEmail,
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
      BranchFields.templateName: templateName,
      BranchFields.assignedInspector: assignedInspector != null
          ? {
              InspectorFields.id: assignedInspector?.id,
              InspectorFields.name: assignedInspector?.name,
            }
          : null,
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
      // New fields
      BranchFields.openingHours: openingHours?.toMap(),
      BranchFields.openingDays: openingDays,
      BranchFields.suppliers: suppliers?.map((e) => e.toMap()).toList(),
      BranchFields.openingDay: openingDay != null
          ? Timestamp.fromDate(openingDay!)
          : null,
      BranchFields.donerPrices: donerPrices,
      BranchFields.software: software,
      BranchFields.shopInformation: shopInformation,
      BranchFields.branchOwners: branchOwners?.map((e) => e.toMap()).toList(),
      BranchFields.branchManagers: branchManagers
          ?.map((e) => e.toMap())
          .toList(),
      BranchFields.branchEmail: branchEmail,
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
      return null;
    }
  }

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

  bool get haveNoScores {
    return last12MonthsScores == null ||
        last12MonthsScores!.every((score) => score == '0');
  }

  String get averagePercent {
    return calculatePerformancePercent(averageScore);
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
