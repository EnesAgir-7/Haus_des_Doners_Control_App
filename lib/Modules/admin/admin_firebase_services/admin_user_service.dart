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

      console('⚠️ No stats found for $monthKey');
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
      avgScore: 0.0,
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
      IHF.avgScore: currentMonthData[IHF.avgScore] ?? defaultModel.avgScore,
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

        // Calculate avgScore from recent scores
        final scores = limitedScores
            .map((s) => double.tryParse(s) ?? 0.0)
            .where((s) => s > 0)
            .toList();
        if (scores.isNotEmpty) {
          final avgScore = scores.reduce((a, b) => a + b) / scores.length;
          monthData[IHF.avgScore] = double.parse(avgScore.toStringAsFixed(2));
        }
      } else if (value is FieldValue) {
        // Handle FieldValue operations
        String valueStr = value.toString();

        if (valueStr.contains('increment')) {
          // Handle increment
          final currentValue = monthData[key] ?? 0;
          monthData[key] = (currentValue is int ? currentValue : 0) + 1;
        }
        // arrayUnion and arrayRemove will be handled below
      } else {
        // Regular field update
        monthData[key] = value;
      }
    }

    // Recalculate avgScore from recentScores
    final scoresList = List<String>.from(monthData[IHF.recentScores] ?? []);
    final numericScores = scoresList
        .map((s) => double.tryParse(s) ?? 0.0)
        .where((s) => s > 0)
        .toList();
    monthData[IHF.avgScore] = numericScores.isNotEmpty
        ? double.parse(
            (numericScores.reduce((a, b) => a + b) / numericScores.length)
                .toStringAsFixed(2),
          )
        : 0.0;

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
      // Month doesn't exist - CREATE with full structure
      batch.set(monthRef, monthData, SetOptions(merge: true));
      console('✅ Created new month $monthKey for inspector $inspectorId');

      // Apply FieldValue operations (arrayUnion, arrayRemove)
      final Map<String, dynamic> fieldValueUpdates = {};
      for (var entry in updates.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is FieldValue) {
          fieldValueUpdates[key] = value;
        }
      }

      if (fieldValueUpdates.isNotEmpty) {
        batch.update(monthRef, fieldValueUpdates);
        console('✅ Applied FieldValue operations for $inspectorId');
      }
    } else {
      // Month exists - UPDATE with FieldValue operations
      final Map<String, dynamic> updateMap = {};

      for (var entry in updates.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is FieldValue) {
          // Use FieldValue directly for arrayUnion, arrayRemove, increment
          updateMap[key] = value;
        } else if (key == IHF.recentScores) {
          // Update recent scores array and avgScore
          updateMap[key] = monthData[key];
          updateMap[IHF.avgScore] = monthData[IHF.avgScore];
        } else {
          // Regular field updates
          updateMap[key] = value;
        }
      }

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

  // Future<void> updateInspectorHistoryBatch({
  //   required WriteBatch batch,
  //   required String inspectorId,
  //   required Map<String, dynamic> updates,
  // }) async {
  //   console("Updating Inspector History Batch");
  //   final inspectorRef = FirebaseFirestore.instance
  //       .collection(Collections.inspectorStats)
  //       .doc(inspectorId);

  //   final inspectorDoc = await inspectorRef.get();

  //   final now = DateTime.now();
  //   final monthKey = '${now.month.toString().padLeft(2, '0')}-${now.year}';

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

  //   Map<String, dynamic> data = {};
  //   bool documentExists = inspectorDoc.exists;

  //   if (documentExists) {
  //     data = inspectorDoc.data() ?? {};
  //   }

  //   // Get current month data or create new one
  //   final currentMonthData =
  //       (data[monthKey] as Map<String, dynamic>?) ?? defaultModel.toMap();

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
  //         // Handle increment - extract value and add to current
  //         final currentValue = monthData[key] ?? 0;
  //         // Increment by 1 (default for FieldValue.increment(1))
  //         monthData[key] = (currentValue is int ? currentValue : 0) + 1;
  //       } else if (valueStr.contains('arrayUnion')) {
  //         // Handle arrayUnion - we need to extract the values
  //         // FieldValue.arrayUnion([value]) adds unique values to array
  //         // For new documents, we need to manually handle this
  //         // This will be handled differently for new vs existing
  //       } else if (valueStr.contains('arrayRemove')) {
  //         // Handle arrayRemove
  //         // This will be handled differently for new vs existing
  //       }
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

  //   // Check if this month already exists in document
  //   bool monthExists = data.containsKey(monthKey);

  //   if (!documentExists || !monthExists) {
  //     // Document doesn't exist OR month doesn't exist
  //     // We need to handle FieldValue operations manually for arrays

  //     // Process FieldValue operations for array fields
  //     for (var entry in updates.entries) {
  //       final key = entry.key;
  //       final value = entry.value;

  //       if (value is FieldValue) {
  //         String valueStr = value.toString();

  //         if (valueStr.contains('arrayUnion')) {
  //           // For arrayUnion: Add values to the array if not present
  //           // We need to parse the FieldValue to get actual values
  //           // Since we can't directly extract from FieldValue, check the key
  //           if (key == IHF.vehicleIds || key == IHF.branchesIds) {
  //             // The caller should pass the actual IDs
  //             // We'll handle this below with a workaround
  //           }
  //         } else if (valueStr.contains('arrayRemove')) {
  //           // For arrayRemove: Remove values from array
  //           // Similar handling as arrayUnion
  //         }
  //       }
  //     }

  //     if (!documentExists) {
  //       // Document doesn't exist - CREATE with full structure
  //       batch.set(inspectorRef, {
  //         IHF.inspectorId: inspectorId,
  //         IHF.lastUpdated: FieldValue.serverTimestamp(),
  //         monthKey: monthData,
  //       }, SetOptions(merge: true)); // Use merge to allow FieldValue operations

  //       console('✅ Created new inspector stats document for $inspectorId');
  //     } else {
  //       // Document exists but month doesn't - ADD month with full structure
  //       batch.set(inspectorRef, {
  //         IHF.lastUpdated: FieldValue.serverTimestamp(),
  //         monthKey: monthData,
  //       }, SetOptions(merge: true)); // Use merge

  //       console('✅ Added new month $monthKey for inspector $inspectorId');
  //     }

  //     // Now apply FieldValue operations using update with dot notation
  //     final Map<String, dynamic> fieldValueUpdates = {};
  //     for (var entry in updates.entries) {
  //       final key = entry.key;
  //       final value = entry.value;

  //       if (value is FieldValue) {
  //         fieldValueUpdates['$monthKey.$key'] = value;
  //       }
  //     }

  //     if (fieldValueUpdates.isNotEmpty) {
  //       batch.update(inspectorRef, fieldValueUpdates);
  //       console('✅ Applied FieldValue operations for $inspectorId');
  //     }
  //   } else {
  //     // Both document and month exist - UPDATE with dot notation
  //     final Map<String, dynamic> updateMap = {
  //       IHF.lastUpdated: FieldValue.serverTimestamp(),
  //     };

  //     // Handle all updates with dot notation
  //     for (var entry in updates.entries) {
  //       final key = entry.key;
  //       final value = entry.value;

  //       if (value is FieldValue) {
  //         // Use dot notation for FieldValue operations
  //         updateMap['$monthKey.$key'] = value;
  //       } else if (key == IHF.recentScores) {
  //         // Update recent scores array
  //         updateMap['$monthKey.$key'] = monthData[key];
  //         updateMap['$monthKey.${IHF.avgScore}'] = monthData[IHF.avgScore];
  //       } else {
  //         // Regular field updates
  //         updateMap['$monthKey.$key'] = value;
  //       }
  //     }

  //     batch.update(inspectorRef, updateMap);
  //     console('✅ Updated existing month $monthKey for inspector $inspectorId');
  //   }

  //   // Prune old months (keep last 12) - only if document exists
  //   if (documentExists) {
  //     _pruneOldMonths(batch, inspectorRef, data, monthKey);
  //   }
  // }

  // =====================================================
  // EXPECTED FIRESTORE STRUCTURE
  // =====================================================

  /*
✅ CORRECT FORMAT:

InspectorStats/inspector123 {
  inspectorId: "inspector123",
  lastUpdated: Timestamp,
  "01-2025": {
    inspectorId: "inspector123",
    totalInspections: 10,
    avgScore: 4.5,
    tasksTotal: 20,
    tasksCompleted: 15,
    recentScores: ["4.5", "5.0", "4.0"],
    vehicleIds: ["vehicle1", "vehicle2"],
    branchesIds: ["branch1", "branch2"]
  },
  "02-2025": {
    inspectorId: "inspector123",
    totalInspections: 8,
    avgScore: 4.8,
    ...
  }
}

❌ WRONG FORMAT (What was happening before):

InspectorStats/inspector123 {
  inspectorId: "inspector123",
  lastUpdated: Timestamp,
  "01-2025": {
    "01-2025.inspectorId": "inspector123",  ❌ WRONG!
    "01-2025.totalInspections": 10,         ❌ WRONG!
    "01-2025.avgScore": 4.5,                ❌ WRONG!
    ...
  }
}

✅ KEY FIXES:
1. Build monthData object WITHOUT monthKey prefix
2. Only use dot notation for FieldValue operations (arrayUnion/arrayRemove)
3. Use map merge for regular field updates
4. Proper structure: { monthKey: { fields } } not { monthKey: { monthKey.fields } }
*/

  // /// Helper: Prune old months, keeping only last 12
  // void _pruneOldMonths(
  //   WriteBatch batch,
  //   DocumentReference inspectorRef,
  //   Map<String, dynamic> data,
  //   String currentMonthKey,
  // ) {
  //   final monthKeys = data.keys
  //       .where((k) => RegExp(r'^\d{2}-\d{4}$').hasMatch(k))
  //       .toList();

  //   if (!monthKeys.contains(currentMonthKey)) {
  //     monthKeys.add(currentMonthKey);
  //   }

  //   // Sort chronologically
  //   monthKeys.sort((a, b) {
  //     final partsA = a.split('-').map(int.parse).toList();
  //     final partsB = b.split('-').map(int.parse).toList();
  //     return DateTime(
  //       partsA[1],
  //       partsA[0],
  //     ).compareTo(DateTime(partsB[1], partsB[0]));
  //   });

  //   // Delete months beyond the 12 most recent
  //   if (monthKeys.length > 12) {
  //     final monthsToDelete = monthKeys.take(monthKeys.length - 12);
  //     final deleteMap = {
  //       for (var oldKey in monthsToDelete) oldKey: FieldValue.delete(),
  //     };
  //     batch.update(inspectorRef, deleteMap);
  //   }
  // }
}
