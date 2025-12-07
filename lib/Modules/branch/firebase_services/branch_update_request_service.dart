import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/branch_update_request_model.dart';
import '../../../models/branch_model.dart';

class BranchUpdateRequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collectionName = Collections.updateRequests;

  // Collection reference
  CollectionReference get _collection => _db.collection(_collectionName);

  // Check if branch has pending request
  Future<bool> hasPendingRequest(String branchId) async {
    try {
      final snapshot = await _collection
          .where('branchId', isEqualTo: branchId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking pending request: $e');
    }
  }

  // Get pending request for branch
  Future<BranchUpdateRequestModel?> getPendingRequest(String branchId) async {
    try {
      final snapshot = await _collection
          .where('branchId', isEqualTo: branchId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return BranchUpdateRequestModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Error getting pending request: $e');
    }
  }

  // Create update request
  Future<String> createUpdateRequest({
    required String branchId,
    required String branchName,
    required String requestedBy,
    required String requestedByName,
    required Map<String, FieldChange> changes,
  }) async {
    try {
      // Check if already has pending request
      final hasPending = await hasPendingRequest(branchId);
      if (hasPending) {
        throw Exception('You already have a pending update request');
      }

      // Create request
      final request = BranchUpdateRequestModel(
        id: branchId,
        branchId: branchId,
        branchName: branchName,
        requestedBy: requestedBy,
        requestedByName: requestedByName,
        requestedAt: DateTime.now(),
        status: 'pending',
        changes: changes,
      );

      final docRef = await _collection.add(request.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating update request: $e');
    }
  }

  // Delete request (only pending requests can be deleted by branch)
  Future<void> deleteRequest(String requestId) async {
    try {
      // First check if it's pending
      final doc = await _collection.doc(requestId).get();
      if (!doc.exists) {
        throw Exception('Request not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] != 'pending') {
        throw Exception('Only pending requests can be deleted');
      }

      await _collection.doc(requestId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting request: $e');
    }
  }

  // Get all requests for a branch (with status filter)
  Future<List<BranchUpdateRequestModel>> getBranchRequests(
    String branchId, {
    String? status,
  }) async {
    try {
      Query query = _collection
          .where('branchId', isEqualTo: branchId)
          .orderBy('requestedAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => BranchUpdateRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting branch requests: $e');
    }
  }

  // Stream for real-time updates
  Stream<BranchUpdateRequestModel?> streamPendingRequest(String branchId) {
    return _collection
        .where('branchId', isEqualTo: branchId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return BranchUpdateRequestModel.fromFirestore(snapshot.docs.first);
        });
  }

  // Compare two branch models and extract changes
  Map<String, FieldChange> compareAndExtractChanges(
    BranchModel oldBranch,
    BranchModel newBranch,
  ) {
    final changes = <String, FieldChange>{};

    // Compare basic fields
    if (oldBranch.name != newBranch.name) {
      changes['name'] = FieldChange(
        fieldName: 'Branch Name',
        oldValue: oldBranch.name,
        newValue: newBranch.name,
        fieldType: 'string',
      );
    }

    if (oldBranch.address != newBranch.address) {
      changes['address'] = FieldChange(
        fieldName: 'Address',
        oldValue: oldBranch.address,
        newValue: newBranch.address,
        fieldType: 'string',
      );
    }

    if (oldBranch.contactName != newBranch.contactName) {
      changes['contactName'] = FieldChange(
        fieldName: 'Contact Name',
        oldValue: oldBranch.contactName,
        newValue: newBranch.contactName,
        fieldType: 'string',
      );
    }

    if (oldBranch.contactPhone != newBranch.contactPhone) {
      changes['contactPhone'] = FieldChange(
        fieldName: 'Contact Phone',
        oldValue: oldBranch.contactPhone,
        newValue: newBranch.contactPhone,
        fieldType: 'string',
      );
    }

    if (oldBranch.branchEmail != newBranch.branchEmail) {
      changes['branchEmail'] = FieldChange(
        fieldName: 'Branch Email',
        oldValue: oldBranch.branchEmail ?? '',
        newValue: newBranch.branchEmail ?? '',
        fieldType: 'string',
      );
    }

    // Compare GPS
    if (oldBranch.gps.latitude != newBranch.gps.latitude ||
        oldBranch.gps.longitude != newBranch.gps.longitude) {
      changes['gps'] = FieldChange(
        fieldName: 'GPS Location',
        oldValue: oldBranch.gps,
        newValue: newBranch.gps,
        fieldType: 'geopoint',
      );
    }

    // Compare opening hours
    if (oldBranch.openingHours?.openingTime !=
            newBranch.openingHours?.openingTime ||
        oldBranch.openingHours?.closingTime !=
            newBranch.openingHours?.closingTime) {
      changes['openingHours'] = FieldChange(
        fieldName: 'Opening Hours',
        oldValue: oldBranch.openingHours?.toMap(),
        newValue: newBranch.openingHours?.toMap(),
        fieldType: 'map',
      );
    }

    // Compare opening days
    if (!_listEquals(oldBranch.openingDays, newBranch.openingDays)) {
      changes['openingDays'] = FieldChange(
        fieldName: 'Opening Days',
        oldValue: oldBranch.openingDays ?? [],
        newValue: newBranch.openingDays ?? [],
        fieldType: 'list',
      );
    }

    // Compare opening day
    if (oldBranch.openingDay != newBranch.openingDay) {
      changes['openingDay'] = FieldChange(
        fieldName: 'Opening Day',
        oldValue: oldBranch.openingDay,
        newValue: newBranch.openingDay,
        fieldType: 'datetime',
      );
    }

    // Compare doner prices
    if (oldBranch.donerPrices != newBranch.donerPrices) {
      changes['donerPrices'] = FieldChange(
        fieldName: 'Doner Prices',
        oldValue: oldBranch.donerPrices ?? '',
        newValue: newBranch.donerPrices ?? '',
        fieldType: 'string',
      );
    }

    // Compare software
    if (oldBranch.software != newBranch.software) {
      changes['software'] = FieldChange(
        fieldName: 'Software',
        oldValue: oldBranch.software ?? '',
        newValue: newBranch.software ?? '',
        fieldType: 'string',
      );
    }

    // Compare shop information
    if (oldBranch.shopInformation != newBranch.shopInformation) {
      changes['shopInformation'] = FieldChange(
        fieldName: 'Shop Information',
        oldValue: oldBranch.shopInformation ?? '',
        newValue: newBranch.shopInformation ?? '',
        fieldType: 'string',
      );
    }

    // Compare branch owners
    if (!_contactPersonListEquals(
      oldBranch.branchOwners,
      newBranch.branchOwners,
    )) {
      changes['branchOwners'] = FieldChange(
        fieldName: 'Branch Owners',
        oldValue: oldBranch.branchOwners?.map((e) => e.toMap()).toList() ?? [],
        newValue: newBranch.branchOwners?.map((e) => e.toMap()).toList() ?? [],
        fieldType: 'list',
      );
    }

    // Compare branch managers
    if (!_contactPersonListEquals(
      oldBranch.branchManagers,
      newBranch.branchManagers,
    )) {
      changes['branchManagers'] = FieldChange(
        fieldName: 'Branch Managers',
        oldValue:
            oldBranch.branchManagers?.map((e) => e.toMap()).toList() ?? [],
        newValue:
            newBranch.branchManagers?.map((e) => e.toMap()).toList() ?? [],
        fieldType: 'list',
      );
    }

    // Compare suppliers
    if (!_contactPersonListEquals(oldBranch.suppliers, newBranch.suppliers)) {
      changes['suppliers'] = FieldChange(
        fieldName: 'Suppliers',
        oldValue: oldBranch.suppliers?.map((e) => e.toMap()).toList() ?? [],
        newValue: newBranch.suppliers?.map((e) => e.toMap()).toList() ?? [],
        fieldType: 'list',
      );
    }

    return changes;
  }

  // Helper to compare lists
  bool _listEquals(List<String>? list1, List<String>? list2) {
    // Both null or both empty - no change
    if ((list1 == null || list1.isEmpty) && (list2 == null || list2.isEmpty)) {
      return true;
    }

    // One is null/empty and the other is not - there's a change
    if ((list1 == null || list1.isEmpty) || (list2 == null || list2.isEmpty)) {
      return false;
    }

    // Both have values - compare length and content
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // Helper to compare contact person lists
  bool _contactPersonListEquals(
    List<ContactPerson>? list1,
    List<ContactPerson>? list2,
  ) {
    // Both null or both empty - no change
    if ((list1 == null || list1.isEmpty) && (list2 == null || list2.isEmpty)) {
      return true;
    }

    // One is null/empty and the other is not - there's a change
    if ((list1 == null || list1.isEmpty) || (list2 == null || list2.isEmpty)) {
      return false;
    }

    // Both have values - compare length and content
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].name != list2[i].name ||
          list1[i].phone != list2[i].phone ||
          list1[i].role != list2[i].role) {
        return false;
      }
    }
    return true;
  }
}
