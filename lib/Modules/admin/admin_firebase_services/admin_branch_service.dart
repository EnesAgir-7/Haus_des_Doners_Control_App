import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_firebase_services/admin_user_service.dart';
import 'package:haus_des_control/core/console.dart';

import '../../../common_services/notification_helper.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../helpers/app_helpers.dart';
import '../../../models/branch_model.dart';
import '../../../translations/locale_keys.g.dart';

class AdminBranchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionBranches = Collections.branches;
  final AdminUserService _userService = AdminUserService();

  // Get all unassigned branches
  Future<List<BranchModel>> getUnassignedBranches() async {
    try {
      final snapshot = await _db
          .collection(_collectionBranches)
          .where(BranchFields.assignedInspector, isNull: true)
          .get();
      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      console('Error getting all branches: $e');
      return [];
    }
  }

  // Get inspector's assigned branches
  Future<List<BranchModel>> getInspectorBranches(String inspectorId) async {
    try {
      final snapshot = await _db
          .collection(_collectionBranches)
          .where('${BranchFields.assignedInspectorId}', isEqualTo: inspectorId)
          .get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting inspector branches: $e');
      return [];
    }
  }

  // Stream all branches (admin, real-time)
  Stream<List<BranchModel>> streamAllBranches() {
    return _db
        .collection(_collectionBranches)
        .orderBy(BranchFields.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BranchModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateBranch(BranchModel branch) async {
    try {
      await _db
          .collection(_collectionBranches)
          .doc(branch.id)
          .update(branch.toMap());
      console('✅ Branch updated successfully');
    } catch (e) {
      print("❌ Error updating branch: $e");
      rethrow;
    }
  }

  /// Add a new branch
  Future<void> addBranch(BranchModel branch) async {
    try {
      // Create a batch
      final batch = _db.batch();

      // Use branch.id as doc id, or generate new one if empty
      final docRef = branch.id.isNotEmpty
          ? _db.collection(_collectionBranches).doc(branch.id)
          : _db.collection(_collectionBranches).doc();

      // Add branch to batch
      batch.set(docRef, {
        BranchFields.id: docRef.id,
        BranchFields.name: branch.name,
        BranchFields.address: branch.address,
        BranchFields.templateId: branch.templateId,
        BranchFields.templateName: branch.templateName,
        BranchFields.gps: branch.gps,
        BranchFields.contactName: branch.contactName,
        BranchFields.contactPhone: branch.contactPhone,
        BranchFields.stop: branch.stop != null ? branch.stop!.toMap() : null,
        BranchFields.assignedInspector: branch.assignedInspector != null
            ? branch.assignedInspector!.toJson()
            : null,
        BranchFields.lastInspectionDate: branch.lastInspectionDate != null
            ? Timestamp.fromDate(branch.lastInspectionDate!)
            : null,
        BranchFields.lastInspectionScore: branch.lastInspectionScore,
        BranchFields.totalInspections: branch.totalInspections,
        BranchFields.averageScore: branch.averageScore,
        BranchFields.status: branch.status,
        BranchFields.last12MonthsScores: branch.last12MonthsScores ?? [],
        BranchFields.createdAt: Timestamp.now(),
        BranchFields.updatedAt: Timestamp.now(),
        // New fields
        BranchFields.branchEmail: branch.branchEmail,
        BranchFields.openingHours: branch.openingHours?.toMap(),
        BranchFields.openingDays: branch.openingDays,
        BranchFields.openingDay: branch.openingDay != null
            ? Timestamp.fromDate(branch.openingDay!)
            : null,
        BranchFields.suppliers: branch.suppliers
            ?.map((e) => e.toMap())
            .toList(),
        BranchFields.donerPrices: branch.donerPrices,
        BranchFields.software: branch.software,
        BranchFields.shopInformation: branch.shopInformation,
        BranchFields.branchOwners: branch.branchOwners
            ?.map((e) => e.toMap())
            .toList(),
        BranchFields.branchManagers: branch.branchManagers
            ?.map((e) => e.toMap())
            .toList(),
      });

      // If inspector is assigned, update their history
      if (branch.assignedInspector != null) {
        await _userService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: branch.assignedInspector!.id,
          updates: {
            IHF.branchesIds: FieldValue.arrayUnion([docRef.id]),
          },
        );
      }

      // Commit the batch
      await batch.commit();
      console('✅ Branch added successfully: ${docRef.id}');

      // ✅ Send notification if inspector is assigned
      if (branch.assignedInspector != null) {
        try {
          // Get inspector's FCM tokens
          final inspectorDoc = await _db
              .collection(Collections.inspectors)
              .doc(branch.assignedInspector!.id)
              .get();

          final inspectorFcmTokens = List<String>.from(
            inspectorDoc.data()?[UserFields.fcmTokens] ?? [],
          );

          if (inspectorFcmTokens.isNotEmpty) {
            console(
              '📤 Sending notification to ${inspectorFcmTokens.length} device(s)',
            );

            await FCMHelper.instance.sendNotificationToMultipleTokens(
              fcmTokens: inspectorFcmTokens,
              title: LocaleKeys.branch_assigned_title.tr(),
              body: LocaleKeys.branch_assigned_body.tr(
                namedArgs: {'branchName': branch.name},
              ),
              data: {
                'type': 'branch_assigned',
                'branchId': docRef.id,
                'branchName': branch.name,
                'branchAddress': branch.address,
                'inspectorId': branch.assignedInspector!.id,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } else {
            console(
              '⚠️ No FCM tokens for inspector ${branch.assignedInspector!.id}',
            );
          }
        } catch (notificationError) {
          // Don't fail the whole operation if notification fails
          console('⚠️ Notification error: $notificationError');
        }
      }
    } catch (e) {
      console('❌ Error adding branch: $e', type: DebugType.error);
      rethrow;
    }
  }

  Stream<List<BranchModel>> streamBranchesByIds(List<String> branchIds) {
    if (branchIds.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection(Collections.branches)
        .where(FieldPath.documentId, whereIn: branchIds)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BranchModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateBranchTemplate({
    required String branchId,
    required String templateId,
    required String templateName,
  }) async {
    try {
      // You should have defined BranchFields as constants for safety
      await _db.collection(_collectionBranches).doc(branchId).update({
        BranchFields.templateId: templateId,
        BranchFields.templateName: templateName,
        BranchFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      });
      console(
        'Branch $branchId template updated to: $templateName ($templateId)',
      );
    } catch (e) {
      print("Error updating branch template: $e");
      rethrow;
    }
  }

  Future<void> removeBranchFromInspector({
    required String inspectorId,
    required String branchId,
    required String branchName,
    required BuildContext context,
  }) async {
    final batch = _db.batch();
    final branchRef = _db.collection(_collectionBranches).doc(branchId);

    try {
      // ✅ 1️⃣ Get inspector's FCM tokens from your helper method
      final inspectorFcmTokens = getInspectorTokens(inspectorId, context);

      // 2️⃣ Unassign branch document
      batch.update(branchRef, {
        BranchFields.assignedInspector: null,
        BranchFields.updatedAt: Timestamp.now(),
      });

      // 3️⃣ Update inspector history
      await _userService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: inspectorId,
        updates: {
          IHF.branchesIds: FieldValue.arrayRemove([branchId]),
        },
      );

      // 4️⃣ Commit batch
      await batch.commit();
      console('✅ Branch $branchId unassigned from inspector $inspectorId');

      // ✅ 5️⃣ Send notification to inspector (errors won't block)
      if (inspectorFcmTokens.isNotEmpty) {
        try {
          console(
            '📤 Sending notification to ${inspectorFcmTokens.length} device(s)',
          );

          final result = await FCMHelper.instance
              .sendNotificationToMultipleTokens(
                fcmTokens: inspectorFcmTokens,
                title: LocaleKeys.branch_unassigned_title.tr(),
                body: LocaleKeys.branch_unassigned_body.tr(
                  namedArgs: {'branchName': branchName},
                ),
                data: {
                  'type': 'branch_unassigned',
                  'branchId': branchId,
                  'branchName': branchName,
                  'inspectorId': inspectorId,
                  'timestamp': DateTime.now().toIso8601String(),
                },
              );

          if (result['success'] == true) {
            console(
              '✅ Notification sent: ${result['successCount']} success, ${result['failureCount']} failed',
            );
          } else {
            console('⚠️ Notification failed to send');
          }
        } catch (e) {
          console('⚠️ Failed to send notification: $e');
        }
      } else {
        console('⚠️ No FCM tokens for inspector $inspectorId');
      }
    } catch (e, st) {
      console('❌ Error unassigning branch: $e\n$st', type: DebugType.error);
      rethrow;
    }
  }

  Future<void> deleteBranch({
    required String branchId,
    required String? inspectorId,
    required BuildContext context,
  }) async {
    final batch = _db.batch();
    final branchRef = _db.collection(_collectionBranches).doc(branchId);

    try {
      // 1️⃣ Delete the branch document
      batch.delete(branchRef);

      // 2️⃣ If an inspector was assigned, update their history
      if (inspectorId != null && inspectorId.isNotEmpty) {
        await _userService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: inspectorId,
          updates: {
            IHF.branchesIds: FieldValue.arrayRemove([branchId]),
          },
        );
      }

      // 3️⃣ Commit batch
      await batch.commit();
      console('✅ Branch $branchId deleted successfully');

      // 4️⃣ Send notification to assigned inspector (if any)
      if (inspectorId != null && inspectorId.isNotEmpty) {
        try {
          final inspectorTokens = getInspectorTokens(inspectorId, context);

          if (inspectorTokens.isNotEmpty) {
            console(
              '📤 Sending branch deletion notification to inspector $inspectorId',
            );

            await FCMHelper.instance.sendNotificationToMultipleTokens(
              fcmTokens: inspectorTokens,
              title: LocaleKeys.branch_deleted_title.tr(),
              body: LocaleKeys.branch_deleted_body.tr(
                namedArgs: {'branchId': branchId},
              ),
              data: {
                'type': 'branch_deleted',
                'branchId': branchId,
                'inspectorId': inspectorId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } else {
            console('⚠️ No FCM tokens for inspector $inspectorId');
          }
        } catch (notificationError) {
          console(
            '⚠️ Failed to send branch deletion notification: $notificationError',
          );
        }
      }
    } catch (e, st) {
      console(
        '❌ Error deleting branch $branchId: $e\n$st',
        type: DebugType.error,
      );
      rethrow;
    }
  }

  Future<void> assignBranchToInspector({
    required String inspectorId,
    required String inspectorName,
    required String branchId,
    required String branchName,
    String? oldInspectorId,
    required BuildContext context,
  }) async {
    final batch = _db.batch();
    final branchRef = _db.collection(_collectionBranches).doc(branchId);

    try {
      // 1️⃣ Update the branch document
      batch.update(branchRef, {
        BranchFields.assignedInspector: {
          InspectorFields.id: inspectorId,
          InspectorFields.name: inspectorName,
        },
        BranchFields.updatedAt: Timestamp.now(),
      });

      // 2️⃣ Remove branch from old inspector's history if different
      if (oldInspectorId != null &&
          oldInspectorId.isNotEmpty &&
          oldInspectorId != inspectorId) {
        await _userService.updateInspectorHistoryBatch(
          batch: batch,
          inspectorId: oldInspectorId,
          updates: {
            IHF.branchesIds: FieldValue.arrayRemove([branchId]),
          },
        );
      }

      // 3️⃣ Add branch to new inspector's history
      await _userService.updateInspectorHistoryBatch(
        batch: batch,
        inspectorId: inspectorId,
        updates: {
          IHF.branchesIds: FieldValue.arrayUnion([branchId]),
        },
      );

      // 4️⃣ Commit the batch
      await batch.commit();
      console('✅ Branch $branchId assigned to $inspectorName');

      // ✅ 5️⃣ Notify OLD inspector (if exists and different)
      if (oldInspectorId != null &&
          oldInspectorId.isNotEmpty &&
          oldInspectorId != inspectorId) {
        try {
          final oldInspectorTokens = getInspectorTokens(
            oldInspectorId,
            context,
          );

          if (oldInspectorTokens.isNotEmpty) {
            console('📤 Notifying old inspector: $oldInspectorId');

            await FCMHelper.instance.sendNotificationToMultipleTokens(
              fcmTokens: oldInspectorTokens,
              title: LocaleKeys.branch_unassigned_title.tr(),
              body: LocaleKeys.branch_unassigned_body.tr(
                namedArgs: {'branchName': branchName},
              ),
              data: {
                'type': 'branch_unassigned',
                'branchId': branchId,
                'branchName': branchName,
                'reason': 'reassigned',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
        } catch (e) {
          console('⚠️ Failed to notify old inspector: $e');
        }
      }

      // ✅ 6️⃣ Notify NEW inspector
      try {
        final newInspectorTokens = getInspectorTokens(inspectorId, context);

        if (newInspectorTokens.isNotEmpty) {
          console('📤 Notifying new inspector: $inspectorId');

          await FCMHelper.instance.sendNotificationToMultipleTokens(
            fcmTokens: newInspectorTokens,
            title: LocaleKeys.branch_assigned_title.tr(),
            body: LocaleKeys.branch_assigned_body.tr(
              namedArgs: {'branchName': branchName},
            ),
            data: {
              'type': 'branch_assigned',
              'branchId': branchId,
              'branchName': branchName,
              'inspectorId': inspectorId,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        } else {
          console('⚠️ No FCM tokens for inspector $inspectorId');
        }
      } catch (e) {
        console('⚠️ Failed to notify new inspector: $e');
      }
    } catch (e, st) {
      console('❌ Error assigning branch: $e\n$st', type: DebugType.error);
      rethrow;
    }
  }
}
