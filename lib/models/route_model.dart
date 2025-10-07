import 'package:cloud_firestore/cloud_firestore.dart';

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
  int order;

  RouteStopModel({
    required this.timeSlot,
    required this.branchId,
    required this.branchName,
    required this.branchTemplateId, 
    required this.status,
    this.inspectionId,
    required this.order,
    this.createdAt,
  });

  factory RouteStopModel.fromMap(Map<String, dynamic> data) {
    return RouteStopModel(
      timeSlot: data['timeSlot'] ?? '',
      branchId: data['branchId'] ?? '',
      branchName: data['branchName'] ?? '',
      branchTemplateId: data["branchTemplateId"],
      status: data['status'] ?? 'pending',
      inspectionId: data['inspectionId'],
      order: data['order'] ?? 0,
      createdAt: data["createdAt"] != null
          ? DateTime.parse(data["createdAt"].toDate().toIso8601String())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeSlot': timeSlot,
      'branchId': branchId,
      'branchName': branchName,
      'status': status,
      'inspectionId': inspectionId,
      'order': order,
      'createdAt': DateTime.now(),
      'branchTemplateId': branchTemplateId, 
    };
  }

  RouteStopModel copyWith({
    String? timeSlot,
    String? branchId,
    String? branchName,
    String? status,
    String? inspectionId,
    String? branchTemplateId,
    int? order,
    DateTime? createdAt,
  }) {
    return RouteStopModel(
      branchTemplateId: branchTemplateId ?? this.branchTemplateId,
      timeSlot: timeSlot ?? this.timeSlot,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      inspectionId: inspectionId ?? this.inspectionId,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isCurrent => status == 'current';
}
