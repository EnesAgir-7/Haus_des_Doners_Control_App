import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String id;
  final String name;
  final String address;
  final String templateId;
  final GeoPoint gps;
  final String contactName;
  final String contactPhone;
  final String assignedInspectorId;
  final DateTime? lastInspectionDate;
  final double? lastInspectionScore;
  final int totalInspections;
  final double averageScore;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchModel( {
    required this.id,
    required this.templateId, 
    required this.name,
    required this.address,
    required this.gps,
    required this.contactName,
    required this.contactPhone,
    required this.assignedInspectorId,
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
      gps: data['gps'] as GeoPoint,
      contactName: data['contactName'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      assignedInspectorId: data['assignedInspectorId'] ?? '',
      lastInspectionDate: data['lastInspectionDate'] != null
          ? (data['lastInspectionDate'] as Timestamp).toDate()
          : null,
      lastInspectionScore: data['lastInspectionScore']?.toDouble(),
      totalInspections: data['totalInspections'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'gps': gps,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'templateId': templateId,
      'assignedInspectorId': assignedInspectorId,
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
