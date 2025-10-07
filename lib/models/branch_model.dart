import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String id;
  final String name;
  final String address;
  final String templateId;
  final String? region;
  final GeoPoint gps;
  final String contactName;
  final String contactPhone;
  final AssignedInspector? assignedInspector;
  final bool isRouteAssigned;
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
    required this.isRouteAssigned,
    this.lastInspectionDate,
    this.lastInspectionScore,
    required this.totalInspections,
    required this.averageScore,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
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
      isRouteAssigned: data['isAssigned'] ?? false,
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
    bool? isRouteAssigned,
    DateTime? lastInspectionDate,
    double? lastInspectionScore,
    int? totalInspections,
    double? averageScore,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      isRouteAssigned: isRouteAssigned ?? this.isRouteAssigned,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      lastInspectionScore: lastInspectionScore ?? this.lastInspectionScore,
      totalInspections: totalInspections ?? this.totalInspections,
      averageScore: averageScore ?? this.averageScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'isAssigned': isRouteAssigned,
      'lastInspectionDate': lastInspectionDate != null
          ? Timestamp.fromDate(lastInspectionDate!)
          : null,
      'lastInspectionScore': lastInspectionScore,
      'totalInspections': totalInspections,
      'averageScore': averageScore,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper method to get days since last inspection
  int? get daysSinceLastInspection {
    if (lastInspectionDate == null) return null;
    return DateTime.now().difference(lastInspectionDate!).inDays;
  }

  // Helper to get formatted last inspection text
  String get lastInspectionText {
    if (lastInspectionDate == null) return 'Henüz kontrol edilmedi';
    final days = daysSinceLastInspection!;
    if (days == 0) return 'Bugün kontrol edildi';
    if (days == 1) return 'Dün kontrol edildi';
    if (days < 7) return '$days gün önce';
    if (days < 30) return '${(days / 7).floor()} hafta önce';
    return '${(days / 30).floor()} ay önce';
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
