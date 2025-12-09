import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/Modules/branch/firebase_services/branch_update_request_service.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

class BranchUpdateRequestModel {
  final String id;
  final String branchId;
  final String branchName;
  final String requestedBy;
  final String requestedByName;
  final DateTime requestedAt;
  final String status; // 'pending', 'approved', 'rejected'
  final Map<String, FieldChange> changes;
  final String? adminNote;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  BranchUpdateRequestModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedAt,
    required this.status,
    required this.changes,
    this.adminNote,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory BranchUpdateRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse changes
    final changesData = data['changes'] as Map<String, dynamic>? ?? {};
    final changes = <String, FieldChange>{};

    changesData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        changes[key] = FieldChange.fromMap(value);
      }
    });

    return BranchUpdateRequestModel(
      id: doc.id,
      branchId: data[BUF.branchId] ?? '',
      branchName: data[BUF.branchName] ?? '',
      requestedBy: data[BUF.requestedBy] ?? '',
      requestedByName: data[BUF.requestedByName] ?? '',
      requestedAt: (data[BUF.requestedAt] as Timestamp).toDate(),
      status: data[BUF.status] ?? 'pending',
      changes: changes,
      adminNote: data[BUF.adminNote],
      reviewedAt: data[BUF.reviewedAt] != null
          ? (data[BUF.reviewedAt] as Timestamp).toDate()
          : null,
      reviewedBy: data[BUF.reviewedBy],
    );
  }

  Map<String, dynamic> toMap() {
    final changesMap = <String, dynamic>{};
    changes.forEach((key, value) {
      changesMap[key] = value.toMap();
    });

    return {
      BUF.branchId: branchId,
      BUF.branchName: branchName,
      BUF.requestedBy: requestedBy,
      BUF.requestedByName: requestedByName,
      BUF.requestedAt: Timestamp.fromDate(requestedAt),
      BUF.status: status,
      BUF.changes: changesMap,
      BUF.adminNote: adminNote,
      BUF.reviewedAt: reviewedAt != null
          ? Timestamp.fromDate(reviewedAt!)
          : null,
      BUF.reviewedBy: reviewedBy,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  int get changeCount => changes.length;
}

class FieldChange {
  final String fieldKey;
  final String fieldName;
  final dynamic oldValue;
  final dynamic newValue;
  final String fieldType; // 'string', 'list', 'map', 'datetime', 'geopoint'

  FieldChange({
    required this.fieldKey,
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.fieldType,
  });

  factory FieldChange.fromMap(Map<String, dynamic> map) {
    return FieldChange(
      fieldKey: map[FCFields.fieldKey] ?? '',
      fieldName: map[FCFields.fieldName] ?? '',
      oldValue: map[FCFields.oldValue],
      newValue: map[FCFields.newValue],
      fieldType: map[FCFields.fieldType] ?? DataTypes.string,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FCFields.fieldKey: fieldKey,
      FCFields.fieldName: fieldName,
      FCFields.oldValue: _serializeValue(oldValue),
      FCFields.newValue: _serializeValue(newValue),
      FCFields.fieldType: fieldType,
    };
  }

  dynamic _serializeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is GeoPoint) return value;
    if (value is List) {
      return value.map((e) => _serializeValue(e)).toList();
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key, _serializeValue(val)));
    }
    return value;
  }

  String get oldValueDisplay => _formatValue(oldValue);
  String get newValueDisplay => _formatValue(newValue);

  String _formatValue(dynamic value) {
    if (value == null) return 'Not set';
    if (value is Timestamp) return value.toDate().toString();
    if (value is GeoPoint) return '${value.latitude}, ${value.longitude}';
    if (value is List) return value.join(', ');
    if (value is Map) return value.toString();
    return value.toString();
  }
}
