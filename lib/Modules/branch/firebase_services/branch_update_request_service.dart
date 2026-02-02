import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../common_services/notification_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/branch_update_request_model.dart';
import '../../../models/branch_model.dart';
import '../../../translations/locale_keys.g.dart' as LK;

class DataTypes {
  static const String string = 'string';
  static const String geopoint = 'geopoint';
  static const String map = 'map';
  static const String list = 'list';
  static const String datetime = 'datetime';
}

class BranchUpdateRequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collectionName = Collections.updateRequests;

  // Collection reference
  CollectionReference get _collection => _db.collection(_collectionName);

  // Check if branch has pending request (for single doc check if needed)
  Future<bool> hasPendingRequest(String requestId) async {
    try {
      final doc = await _collection.doc(requestId).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      return data['status'] == 'pending';
    } catch (e) {
      throw Exception('${LK.LocaleKeys.error_checking_pending_request.tr()}$e');
    }
  }

  // Check if branch HAS at least one pending request in the collection
  Future<bool> hasAnyPendingRequest(String branchId) async {
    try {
      final snapshot = await _collection
          .where('branchId', isEqualTo: branchId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('${LK.LocaleKeys.error_checking_pending_request.tr()}$e');
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

      // Pass the data + id to your model factory
      return BranchUpdateRequestModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('${LK.LocaleKeys.error_getting_pending_request.tr()}$e');
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
      final hasPending = await hasAnyPendingRequest(branchId);
      if (hasPending) {
        throw Exception(LK.LocaleKeys.already_pending_request.tr());
      }

      // Unique ID including timestamp for history
      final requestId = "${branchId}_${DateTime.now().millisecondsSinceEpoch}";

      // Create request model
      final request = BranchUpdateRequestModel(
        id: requestId,
        branchId: branchId,
        branchName: branchName,
        requestedBy: requestedBy,
        requestedByName: requestedByName,
        requestedAt: DateTime.now(),
        status: 'pending',
        changes: changes,
      );

      // Store doc using timestamped ID
      await _collection.doc(requestId).set(request.toMap());
      NotificationHelper.instance.sendNotificationToTopic(
        topic: AppConstants.adminTopic,
        title: LK.LocaleKeys.branch_update_request_title.tr(),
        body: '${LK.LocaleKeys.branch_update_request_body.tr()} $branchName.',
        data: {
          'type': 'branch_update_request',
          'branchId': branchId,
          'requestId': requestId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return requestId;
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('${LK.LocaleKeys.error_creating_update_request.tr()}$e');
    }
  }

  // Delete request (only pending requests can be deleted by branch)
  Future<void> deleteRequest(String requestId) async {
    try {
      // Fetch request
      final doc = await _collection.doc(requestId).get();
      if (!doc.exists) {
        throw Exception(LK.LocaleKeys.request_not_found.tr());
      }

      final data = doc.data() as Map<String, dynamic>?; // Safe cast
      if (data == null) {
        throw Exception(LK.LocaleKeys.invalid_request_format.tr());
      }

      // Only allow deleting pending requests
      if (data['status'] != 'pending') {
        throw Exception(LK.LocaleKeys.only_pending_can_be_deleted.tr());
      }

      // Delete the request
      await _collection.doc(requestId).delete();
    } on FirebaseException catch (e) {
      throw Exception('${LK.LocaleKeys.firebase_error.tr()}${e.message}');
    } catch (e) {
      throw Exception('${LK.LocaleKeys.error_deleting_request.tr()}$e');
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
      throw Exception('${LK.LocaleKeys.error_getting_branch_requests.tr()}$e');
    }
  }

  // Compare two branch models and extract changes
  Map<String, FieldChange> compareAndExtractChanges(
    BranchModel oldBranch,
    BranchModel newBranch,
  ) {
    final changes = <String, FieldChange>{};

    // Compare basic fields
    if (oldBranch.name != newBranch.name) {
      changes[BranchFields.name] = FieldChange(
        fieldKey: BranchFields.name,
        fieldName: LK.LocaleKeys.branchName, // Key instead of translated name
        oldValue: oldBranch.name,
        newValue: newBranch.name,
        fieldType: DataTypes.string,
      );
    }

    if (oldBranch.address != newBranch.address) {
      changes[BranchFields.address] = FieldChange(
        fieldKey: BranchFields.address,
        fieldName: LK.LocaleKeys.address,
        oldValue: oldBranch.address,
        newValue: newBranch.address,
        fieldType: DataTypes.string,
      );
    }

    if (oldBranch.contactName != newBranch.contactName) {
      changes[BranchFields.contactName] = FieldChange(
        fieldKey: BranchFields.contactName,
        fieldName: LK.LocaleKeys.contactName,
        oldValue: oldBranch.contactName,
        newValue: newBranch.contactName,
        fieldType: DataTypes.string,
      );
    }

    if (oldBranch.contactPhone != newBranch.contactPhone) {
      changes[BranchFields.contactPhone] = FieldChange(
        fieldKey: BranchFields.contactPhone,
        fieldName: LK.LocaleKeys.contactPhone,
        oldValue: oldBranch.contactPhone,
        newValue: newBranch.contactPhone,
        fieldType: DataTypes.string,
      );
    }

    // Compare GPS
    if (oldBranch.gps.latitude != newBranch.gps.latitude ||
        oldBranch.gps.longitude != newBranch.gps.longitude) {
      changes[BranchFields.gps] = FieldChange(
        fieldKey: BranchFields.gps,
        fieldName: LK.LocaleKeys.gps,
        oldValue: oldBranch.gps,
        newValue: newBranch.gps,
        fieldType: DataTypes.geopoint,
      );
    }

    // Compare opening hours
    if (oldBranch.openingHours?.openingTime !=
            newBranch.openingHours?.openingTime ||
        oldBranch.openingHours?.closingTime !=
            newBranch.openingHours?.closingTime) {
      changes[BranchFields.openingHours] = FieldChange(
        fieldKey: BranchFields.openingHours,
        fieldName: LK.LocaleKeys.openingHoursDays,
        oldValue: oldBranch.openingHours?.toMap(),
        newValue: newBranch.openingHours?.toMap(),
        fieldType: DataTypes.map,
      );
    }

    // Compare opening days
    if (!_listEquals(oldBranch.openingDays, newBranch.openingDays)) {
      changes[BranchFields.openingDays] = FieldChange(
        fieldKey: BranchFields.openingDays,
        fieldName: LK.LocaleKeys.openingDays,
        oldValue: oldBranch.openingDays ?? [],
        newValue: newBranch.openingDays ?? [],
        fieldType: DataTypes.list,
      );
    }

    // Compare opening day
    if (oldBranch.openingDay != newBranch.openingDay) {
      changes[BranchFields.openingDay] = FieldChange(
        fieldKey: BranchFields.openingDay,
        fieldName: LK.LocaleKeys.openingDay,
        oldValue: oldBranch.openingDay,
        newValue: newBranch.openingDay,
        fieldType: DataTypes.datetime,
      );
    }

    // Compare doner prices
    if (oldBranch.donerPrices != newBranch.donerPrices) {
      changes[BranchFields.donerPrices] = FieldChange(
        fieldKey: BranchFields.donerPrices,
        fieldName: LK.LocaleKeys.donerPrices,
        oldValue: oldBranch.donerPrices ?? '',
        newValue: newBranch.donerPrices ?? '',
        fieldType: DataTypes.string,
      );
    }

    // Compare software
    if (oldBranch.software != newBranch.software) {
      changes[BranchFields.software] = FieldChange(
        fieldKey: BranchFields.software,
        fieldName: LK.LocaleKeys.software,
        oldValue: oldBranch.software ?? '',
        newValue: newBranch.software ?? '',
        fieldType: DataTypes.string,
      );
    }

    // Compare shop information
    if (oldBranch.shopInformation != newBranch.shopInformation) {
      changes[BranchFields.shopInformation] = FieldChange(
        fieldKey: BranchFields.shopInformation,
        fieldName: LK.LocaleKeys.shopInformation,
        oldValue: oldBranch.shopInformation ?? '',
        newValue: newBranch.shopInformation ?? '',
        fieldType: DataTypes.string,
      );
    }

    // Compare branch owners
    if (!_contactPersonListEquals(
      oldBranch.branchOwners,
      newBranch.branchOwners,
    )) {
      changes[BranchFields.branchOwners] = FieldChange(
        fieldKey: BranchFields.branchOwners,
        fieldName: LK.LocaleKeys.branchOwners,
        oldValue: oldBranch.branchOwners?.map((e) => e.toMap()).toList() ?? [],
        newValue: newBranch.branchOwners?.map((e) => e.toMap()).toList() ?? [],
        fieldType: DataTypes.list,
      );
    }

    // Compare branch managers
    if (!_contactPersonListEquals(
      oldBranch.branchManagers,
      newBranch.branchManagers,
    )) {
      changes[BranchFields.branchManagers] = FieldChange(
        fieldKey: BranchFields.branchManagers,
        fieldName: LK.LocaleKeys.branchManagers,
        oldValue:
            oldBranch.branchManagers?.map((e) => e.toMap()).toList() ?? [],
        newValue:
            newBranch.branchManagers?.map((e) => e.toMap()).toList() ?? [],
        fieldType: DataTypes.list,
      );
    }

    // Compare suppliers
    if (!_contactPersonListEquals(oldBranch.suppliers, newBranch.suppliers)) {
      changes[BranchFields.suppliers] = FieldChange(
        fieldKey: BranchFields.suppliers,
        fieldName: LK.LocaleKeys.suppliers,
        oldValue: oldBranch.suppliers?.map((e) => e.toMap()).toList() ?? [],
        newValue: newBranch.suppliers?.map((e) => e.toMap()).toList() ?? [],
        fieldType: DataTypes.list,
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
