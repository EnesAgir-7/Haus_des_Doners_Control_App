import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../core/constants/app_constants.dart';
import '../../../helpers/local_storage_helper.dart';
import '../../../models/inspector_history_model.dart';
import '../../../models/user_model.dart';

class AdminUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream all inspectors

  Stream<List<UserModel>> streamAllInspectors() {
    try {
      return _db.collection(Collections.inspectors).snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error streaming all inspectors: $e');
      // Return an empty stream in case of error
      return Stream.value([]);
    }
  }

  Future<InspectorHistoryModel?> getInspectorMonthStats(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final monthKey = '${month.toString().padLeft(2, '0')}-$year';

      final monthDoc = await _db
          .collection(Collections.inspectorStats)
          .doc(userId)
          .collection('months')
          .doc(monthKey)
          .get();

      if (monthDoc.exists) {
        final data = monthDoc.data();
        if (data == null) return null;

        return InspectorHistoryModel.fromMap(data);
      }
      return null;
    } catch (e) {
      console('❌ Error fetching month stats: $e');
      rethrow;
    }
  }

  Future<List<String>> getAvailableMonths(String userId) async {
    try {
      final monthsSnapshot = await _db
          .collection(Collections.inspectorStats)
          .doc(userId)
          .collection('months')
          .get();

      final monthKeys = monthsSnapshot.docs.map((doc) => doc.id).toList();
      monthKeys.sort(); // Sort chronologically

      return monthKeys;
    } catch (e) {
      console('❌ Error fetching available months: $e');
      return [];
    }
  }

  // Update inspector
  Future<void> updateInspector(String userId, Map<String, dynamic> data) async {
    try {
      data[UserFields.updatedAt] = FieldValue.serverTimestamp();
      await _db.collection(Collections.inspectors).doc(userId).update(data);
    } catch (e) {
      print('Error updating inspector: $e');
      rethrow;
    }
  }

  Future<void> updateUserDetails({
    required String userId,
    String? name,
    String? region,
    String? role,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    try {
      // Get current user data to determine collection
      DocumentSnapshot? userDoc;
      DocumentReference? userRef;

      // Try inspectors first
      userRef = _db.collection(Collections.inspectors).doc(userId);
      userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Try admins
        userRef = _db.collection(Collections.admins).doc(userId);
        userDoc = await userRef.get();
      }

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final Map<String, dynamic> updates = {};

      // Build updates map
      if (name != null) updates[UserFields.name] = name;
      if (region != null)
        updates[UserFields.region] = region.isEmpty ? null : region;
      if (role != null) updates[UserFields.role] = role;
      updates[UserFields.updatedAt] = FieldValue.serverTimestamp();

      // Update Firestore document
      batch.update(userRef, updates);

      // Commit batch
      await batch.commit();

      // If logged-in user is updated, update local cache
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        final updatedDoc = await userRef.get();
        final updatedUserModel = UserModel.fromFirestore(updatedDoc);

        // Update local storage
        loggedInUser = updatedUserModel;
        await LocalStorageHelper.instance.saveData(
          cacheUserKey,
          updatedUserModel.toMap(),
        );
      }

      console('✅ User updated successfully');
    } catch (e, st) {
      console('❌ Error updating user: $e\n$st');
      rethrow;
    }
  }

  // Create user (inspector or admin)
  Future<void> createUser(String userId, UserModel user) async {
    try {
      String collectionName;
      switch (user.role.toLowerCase()) {
        case AppConstants.inspector:
          collectionName = Collections.inspectors;
          break;
        case AppConstants.admin:
          collectionName = Collections.admins;
          break;
        default:
          throw Exception('Invalid user role: ${user.role}');
      }

      await _db.collection(collectionName).doc(userId).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Future<void> updateInspectorHistoryBatch({
  //   required WriteBatch batch,
  //   required String inspectorId,
  //   required Map<String, dynamic> updates,
  // }) async {
  //   console("Updating Inspector History Batch");

  //   final inspectorRef = FirebaseFirestore.instance
  //       .collection(Collections.inspectorStats)
  //       .doc(inspectorId);

  //   final now = DateTime.now();
  //   final monthKey = '${now.month.toString().padLeft(2, '0')}-${now.year}';

  //   // Reference to the month subcollection document
  //   final monthRef = inspectorRef.collection('months').doc(monthKey);

  //   final inspectorDoc = await inspectorRef.get();
  //   final monthDoc = await monthRef.get();

  //   // Default model values
  //   InspectorHistoryModel defaultModel = InspectorHistoryModel(
  //     inspectorId: inspectorId,
  //     totalInspections: 0,
  //     avgScore: 0.0,
  //     tasksTotal: 0,
  //     tasksCompleted: 0,
  //     recentScores: [],
  //     vehicleIds: [],
  //     branchesIds: [],
  //     lastUpdated: now,
  //   );

  //   bool documentExists = inspectorDoc.exists;
  //   bool monthExists = monthDoc.exists;

  //   // Get current month data or create new one
  //   Map<String, dynamic> currentMonthData = monthExists
  //       ? (monthDoc.data() ?? defaultModel.toMap())
  //       : defaultModel.toMap();

  //   // Build the month object with all fields
  //   Map<String, dynamic> monthData = {
  //     IHF.inspectorId: inspectorId,
  //     IHF.totalInspections:
  //         currentMonthData[IHF.totalInspections] ??
  //         defaultModel.totalInspections,
  //     IHF.avgScore: currentMonthData[IHF.avgScore] ?? defaultModel.avgScore,
  //     IHF.tasksTotal:
  //         currentMonthData[IHF.tasksTotal] ?? defaultModel.tasksTotal,
  //     IHF.tasksCompleted:
  //         currentMonthData[IHF.tasksCompleted] ?? defaultModel.tasksCompleted,
  //     IHF.recentScores: List<String>.from(
  //       currentMonthData[IHF.recentScores] ?? defaultModel.recentScores,
  //     ),
  //     IHF.vehicleIds: List<String>.from(
  //       currentMonthData[IHF.vehicleIds] ?? defaultModel.vehicleIds,
  //     ),
  //     IHF.branchesIds: List<String>.from(
  //       currentMonthData[IHF.branchesIds] ?? defaultModel.branchesIds,
  //     ),
  //     IHF.lastUpdated: FieldValue.serverTimestamp(),
  //   };

  //   // Apply updates to monthData BEFORE creating/updating
  //   for (var entry in updates.entries) {
  //     final key = entry.key;
  //     final value = entry.value;

  //     if (key == IHF.recentScores && value is List) {
  //       // Handle recent scores - ADD to existing scores
  //       final existingScores = List<String>.from(
  //         monthData[IHF.recentScores] ?? [],
  //       );
  //       final newScores = value.cast<String>();
  //       final allScores = [...existingScores, ...newScores];

  //       // Keep only last 10 scores
  //       final limitedScores = allScores.length > 10
  //           ? allScores.sublist(allScores.length - 10)
  //           : allScores;

  //       monthData[key] = limitedScores;

  //       // Calculate avgScore from recent scores
  //       final scores = limitedScores
  //           .map((s) => double.tryParse(s) ?? 0.0)
  //           .where((s) => s > 0)
  //           .toList();
  //       if (scores.isNotEmpty) {
  //         final avgScore = scores.reduce((a, b) => a + b) / scores.length;
  //         monthData[IHF.avgScore] = double.parse(avgScore.toStringAsFixed(2));
  //       }
  //     } else if (value is FieldValue) {
  //       // Handle FieldValue operations
  //       String valueStr = value.toString();

  //       if (valueStr.contains('increment')) {
  //         // Handle increment
  //         final currentValue = monthData[key] ?? 0;
  //         monthData[key] = (currentValue is int ? currentValue : 0) + 1;
  //       }
  //       // arrayUnion and arrayRemove will be handled below
  //     } else {
  //       // Regular field update
  //       monthData[key] = value;
  //     }
  //   }

  //   // Recalculate avgScore from recentScores
  //   final scoresList = List<String>.from(monthData[IHF.recentScores] ?? []);
  //   final numericScores = scoresList
  //       .map((s) => double.tryParse(s) ?? 0.0)
  //       .where((s) => s > 0)
  //       .toList();
  //   monthData[IHF.avgScore] = numericScores.isNotEmpty
  //       ? double.parse(
  //           (numericScores.reduce((a, b) => a + b) / numericScores.length)
  //               .toStringAsFixed(2),
  //         )
  //       : 0.0;

  //   // 1️⃣ Update/Create parent inspector document
  //   if (!documentExists) {
  //     batch.set(inspectorRef, {
  //       IHF.inspectorId: inspectorId,
  //       IHF.lastUpdated: FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //     console('✅ Created inspector document for $inspectorId');
  //   } else {
  //     batch.update(inspectorRef, {
  //       IHF.lastUpdated: FieldValue.serverTimestamp(),
  //     });
  //   }

  //   // 2️⃣ Handle month subcollection document
  //   if (!monthExists) {
  //     // Month doesn't exist - CREATE with full structure
  //     batch.set(monthRef, monthData, SetOptions(merge: true));
  //     console('✅ Created new month $monthKey for inspector $inspectorId');

  //     // Apply FieldValue operations (arrayUnion, arrayRemove)
  //     final Map<String, dynamic> fieldValueUpdates = {};
  //     for (var entry in updates.entries) {
  //       final key = entry.key;
  //       final value = entry.value;

  //       if (value is FieldValue) {
  //         fieldValueUpdates[key] = value;
  //       }
  //     }

  //     if (fieldValueUpdates.isNotEmpty) {
  //       batch.update(monthRef, fieldValueUpdates);
  //       console('✅ Applied FieldValue operations for $inspectorId');
  //     }
  //   } else {
  //     // Month exists - UPDATE with FieldValue operations
  //     final Map<String, dynamic> updateMap = {};

  //     for (var entry in updates.entries) {
  //       final key = entry.key;
  //       final value = entry.value;

  //       if (value is FieldValue) {
  //         // Use FieldValue directly for arrayUnion, arrayRemove, increment
  //         updateMap[key] = value;
  //       } else if (key == IHF.recentScores) {
  //         // Update recent scores array and avgScore
  //         updateMap[key] = monthData[key];
  //         updateMap[IHF.avgScore] = monthData[IHF.avgScore];
  //       } else {
  //         // Regular field updates
  //         updateMap[key] = value;
  //       }
  //     }

  //     // Always update lastUpdated
  //     updateMap[IHF.lastUpdated] = FieldValue.serverTimestamp();

  //     batch.update(monthRef, updateMap);
  //     console('✅ Updated existing month $monthKey for inspector $inspectorId');
  //   }

  //   // 3️⃣ Prune old months (keep last 12) - only if document exists
  //   if (documentExists) {
  //     await _pruneOldMonthsSubcollection(batch, inspectorRef, monthKey);
  //   }
  // }

  Future<void> updateInspectorHistoryBatch({
    required WriteBatch batch,
    required String inspectorId,
    required Map<String, dynamic> updates,
  }) async {
    console("Updating Inspector History Batch");

    final inspectorRef = FirebaseFirestore.instance
        .collection(Collections.inspectorStats)
        .doc(inspectorId);

    final now = DateTime.now();
    final monthKey = '${now.month.toString().padLeft(2, '0')}-${now.year}';

    // Reference to the month subcollection document
    final monthRef = inspectorRef.collection('months').doc(monthKey);

    final inspectorDoc = await inspectorRef.get();
    final monthDoc = await monthRef.get();

    // Default model values
    InspectorHistoryModel defaultModel = InspectorHistoryModel(
      inspectorId: inspectorId,
      totalInspections: 0,
      tasksTotal: 0,
      tasksCompleted: 0,
      recentScores: [],
      vehicleIds: [],
      branchesIds: [],
      lastUpdated: now,
    );

    bool documentExists = inspectorDoc.exists;
    bool monthExists = monthDoc.exists;

    // Get current month data or create new one
    Map<String, dynamic> currentMonthData = monthExists
        ? (monthDoc.data() ?? defaultModel.toMap())
        : defaultModel.toMap();

    // Build the month object with all fields
    Map<String, dynamic> monthData = {
      IHF.inspectorId: inspectorId,
      IHF.totalInspections:
          currentMonthData[IHF.totalInspections] ??
          defaultModel.totalInspections,
      IHF.tasksTotal:
          currentMonthData[IHF.tasksTotal] ?? defaultModel.tasksTotal,
      IHF.tasksCompleted:
          currentMonthData[IHF.tasksCompleted] ?? defaultModel.tasksCompleted,
      IHF.recentScores: List<String>.from(
        currentMonthData[IHF.recentScores] ?? defaultModel.recentScores,
      ),
      IHF.vehicleIds: List<String>.from(
        currentMonthData[IHF.vehicleIds] ?? defaultModel.vehicleIds,
      ),
      IHF.branchesIds: List<String>.from(
        currentMonthData[IHF.branchesIds] ?? defaultModel.branchesIds,
      ),
      IHF.lastUpdated: FieldValue.serverTimestamp(),
    };

    // Separate updates into FieldValue operations and regular updates
    Map<String, dynamic> regularUpdates = {};
    Map<String, dynamic> fieldValueUpdates = {};

    // Apply updates to monthData BEFORE creating/updating
    for (var entry in updates.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key == IHF.recentScores && value is List) {
        // Handle recent scores - ADD to existing scores
        final existingScores = List<String>.from(
          monthData[IHF.recentScores] ?? [],
        );
        final newScores = value.cast<String>();
        final allScores = [...existingScores, ...newScores];

        // Keep only last 10 scores
        final limitedScores = allScores.length > 10
            ? allScores.sublist(allScores.length - 10)
            : allScores;

        monthData[key] = limitedScores;
        regularUpdates[key] = limitedScores;
      } else if (value is FieldValue) {
        // Store FieldValue operations separately for proper batch handling
        fieldValueUpdates[key] = value;
      } else {
        // Regular field update
        monthData[key] = value;
        regularUpdates[key] = value;
      }
    }

    // 1️⃣ Update/Create parent inspector document
    if (!documentExists) {
      batch.set(inspectorRef, {
        IHF.inspectorId: inspectorId,
        IHF.lastUpdated: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      console('✅ Created inspector document for $inspectorId');
    } else {
      batch.update(inspectorRef, {
        IHF.lastUpdated: FieldValue.serverTimestamp(),
      });
    }

    // 2️⃣ Handle month subcollection document
    if (!monthExists) {
      // Month doesn't exist - CREATE with initial structure (no FieldValues)
      final Map<String, dynamic> createData = Map.from(monthData);

      // Remove any FieldValue objects from initial creation
      createData.removeWhere((key, value) => value is FieldValue);

      batch.set(monthRef, createData, SetOptions(merge: true));
      console('✅ Created new month $monthKey for inspector $inspectorId');

      // Apply FieldValue operations after document creation
      if (fieldValueUpdates.isNotEmpty) {
        batch.update(monthRef, {
          ...fieldValueUpdates,
          IHF.lastUpdated: FieldValue.serverTimestamp(),
        });
        console('✅ Applied FieldValue operations for $inspectorId');
      }
    } else {
      // Month exists - UPDATE with all changes
      final Map<String, dynamic> updateMap = {};

      // Add regular updates
      updateMap.addAll(regularUpdates);

      // Add FieldValue operations
      updateMap.addAll(fieldValueUpdates);

      // Always update lastUpdated
      updateMap[IHF.lastUpdated] = FieldValue.serverTimestamp();

      batch.update(monthRef, updateMap);
      console('✅ Updated existing month $monthKey for inspector $inspectorId');
    }

    // 3️⃣ Prune old months (keep last 12) - only if document exists
    if (documentExists) {
      await _pruneOldMonthsSubcollection(batch, inspectorRef, monthKey);
    }
  }

  Future<void> _pruneOldMonthsSubcollection(
    WriteBatch batch,
    DocumentReference inspectorRef,
    String currentMonthKey,
  ) async {
    try {
      // Get all month documents
      final monthsSnapshot = await inspectorRef.collection('months').get();

      if (monthsSnapshot.docs.length <= 12) {
        return; // No pruning needed
      }

      // Parse month keys and sort them
      final monthKeys = monthsSnapshot.docs.map((doc) => doc.id).toList();
      monthKeys.sort((a, b) {
        // Parse format: "MM-YYYY"
        final aParts = a.split('-');
        final bParts = b.split('-');

        final aDate = DateTime(int.parse(aParts[1]), int.parse(aParts[0]));
        final bDate = DateTime(int.parse(bParts[1]), int.parse(bParts[0]));

        return aDate.compareTo(bDate);
      });

      // Keep only last 12 months
      final monthsToDelete = monthKeys.length > 12
          ? monthKeys.sublist(0, monthKeys.length - 12)
          : <String>[];

      for (final monthKey in monthsToDelete) {
        final monthDoc = inspectorRef.collection('months').doc(monthKey);
        batch.delete(monthDoc);
        console('🗑️ Marked month $monthKey for deletion');
      }

      console('✅ Pruned ${monthsToDelete.length} old months');
    } catch (e) {
      console('⚠️ Error pruning old months: $e');
    }
  }
}
