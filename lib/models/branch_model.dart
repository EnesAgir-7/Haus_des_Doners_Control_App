import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

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
  final AssignedInspector? assignedInspector;
  final DateTime? lastInspectionDate;
  final double? lastInspectionScore;
  final int totalInspections;
  final double averageScore;
  final String status;
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
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      templateId: data['templateId'] ?? '',
      region: data['region'],
      gps: data['gps'] as GeoPoint,
      contactName: data['contactName'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      assignedInspector: data['assignedInspector'] != null
          ? AssignedInspector(
              id: data['assignedInspector']['id'] ?? '',
              name: data['assignedInspector']['name'] ?? '',
            )
          : null,
      lastInspectionDate: data['lastInspectionDate'] != null
          ? (data['lastInspectionDate'] as Timestamp).toDate()
          : null,
      lastInspectionScore: data['lastInspectionScore']?.toDouble(),
      totalInspections: data['totalInspections'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'active',
      createdAt: data["createdAt"] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data["updatedAt"] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      stop: data['stop'] != null
          ? RouteStopModel.fromMap(Map<String, dynamic>.from(data['stop']))
          : null,
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
    double? lastInspectionScore,
    int? totalInspections,
    double? averageScore,
    String? status,
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stop: stop ?? this.stop, // ✅ Preserve or override
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'region': region,
      'gps': gps,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'templateId': templateId,
      'assignedInspector': {
        'id': assignedInspector?.id,
        'name': assignedInspector?.name,
      },
      'lastInspectionDate': lastInspectionDate != null
          ? Timestamp.fromDate(lastInspectionDate!)
          : null,
      'lastInspectionScore': lastInspectionScore,
      'totalInspections': totalInspections,
      'averageScore': averageScore,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'stop': stop?.toMap(), // ✅ Serialize stop object if present
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
    if (lastInspectionDate == null) return 'Henüz kontrol edilmedi';
    final days = daysSinceLastInspection!;
    if (days == 0) return 'Bugün kontrol edildi';
    if (days == 1) return 'Dün kontrol edildi';
    if (days < 7) return '$days gün önce';
    if (days < 30) return '${(days / 7).floor()} hafta önce';
    return '${(days / 30).floor()} ay önce';
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
    return AssignedInspector(id: map['id'] ?? '', name: map['name'] ?? '');
  }
}
