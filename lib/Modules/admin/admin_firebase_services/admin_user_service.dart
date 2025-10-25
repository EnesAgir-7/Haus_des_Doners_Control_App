import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../core/constants/app_constants.dart';
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

  Future<InspectorAllMonthsData?> getInspectorStats(String userId) async {
    try {
      final docRef = _db.collection(Collections.inspectorStats).doc(userId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();

        if (data == null) return null;

        final inspectorId = data['inspectorId'] ?? userId;
        final lastUpdated = data['lastUpdated'] != null
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now();

        final monthsData = <String, InspectorHistoryModel>{};

        // Loop through all fields to find month keys (e.g., "01-2025", "02-2025")
        for (var entry in data.entries) {
          final key = entry.key;

          // Check if key matches month format (MM-YYYY)
          if (RegExp(r'^\d{2}-\d{4}$').hasMatch(key)) {
            final value = entry.value as Map<String, dynamic>;

            // Parse month and year from key
            final parts = key.split('-');
            final month = int.parse(parts[0]);
            final year = int.parse(parts[1]);

            // Add missing fields
            value['inspectorId'] = inspectorId;
            value['year'] = year;
            value['month'] = month;

            monthsData[key] = InspectorHistoryModel.fromMap(value);
          }
        }

        return InspectorAllMonthsData(
          inspectorId: inspectorId,
          monthsData: monthsData,
          lastUpdated: lastUpdated,
        );
      } else {
        print('⚠️ Inspector stats document not found for ID: $userId');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching inspector stats: $e');
      rethrow;
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

    final inspectorDoc = await inspectorRef.get();

    final now = DateTime.now();
    final monthKey = '${now.month.toString().padLeft(2, '0')}-${now.year}';

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

    Map<String, dynamic> data = {};
    bool documentExists = inspectorDoc.exists;

    if (documentExists) {
      data = inspectorDoc.data() ?? {};
    }

    // Get current month data or create new one
    final currentMonthData =
        (data[monthKey] as Map<String, dynamic>?) ?? defaultModel.toMap();

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
          // Handle increment - extract value and add to current
          final currentValue = monthData[key] ?? 0;
          // Increment by 1 (default for FieldValue.increment(1))
          monthData[key] = (currentValue is int ? currentValue : 0) + 1;
        } else if (valueStr.contains('arrayUnion')) {
          // Handle arrayUnion - we need to extract the values
          // FieldValue.arrayUnion([value]) adds unique values to array
          // For new documents, we need to manually handle this
          // This will be handled differently for new vs existing
        } else if (valueStr.contains('arrayRemove')) {
          // Handle arrayRemove
          // This will be handled differently for new vs existing
        }
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

    // Check if this month already exists in document
    bool monthExists = data.containsKey(monthKey);

    if (!documentExists || !monthExists) {
      // Document doesn't exist OR month doesn't exist
      // We need to handle FieldValue operations manually for arrays

      // Process FieldValue operations for array fields
      for (var entry in updates.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is FieldValue) {
          String valueStr = value.toString();

          if (valueStr.contains('arrayUnion')) {
            // For arrayUnion: Add values to the array if not present
            // We need to parse the FieldValue to get actual values
            // Since we can't directly extract from FieldValue, check the key
            if (key == IHF.vehicleIds || key == IHF.branchesIds) {
              // The caller should pass the actual IDs
              // We'll handle this below with a workaround
            }
          } else if (valueStr.contains('arrayRemove')) {
            // For arrayRemove: Remove values from array
            // Similar handling as arrayUnion
          }
        }
      }

      if (!documentExists) {
        // Document doesn't exist - CREATE with full structure
        batch.set(inspectorRef, {
          IHF.inspectorId: inspectorId,
          IHF.lastUpdated: FieldValue.serverTimestamp(),
          monthKey: monthData,
        }, SetOptions(merge: true)); // Use merge to allow FieldValue operations

        console('✅ Created new inspector stats document for $inspectorId');
      } else {
        // Document exists but month doesn't - ADD month with full structure
        batch.set(inspectorRef, {
          IHF.lastUpdated: FieldValue.serverTimestamp(),
          monthKey: monthData,
        }, SetOptions(merge: true)); // Use merge

        console('✅ Added new month $monthKey for inspector $inspectorId');
      }

      // Now apply FieldValue operations using update with dot notation
      final Map<String, dynamic> fieldValueUpdates = {};
      for (var entry in updates.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is FieldValue) {
          fieldValueUpdates['$monthKey.$key'] = value;
        }
      }

      if (fieldValueUpdates.isNotEmpty) {
        batch.update(inspectorRef, fieldValueUpdates);
        console('✅ Applied FieldValue operations for $inspectorId');
      }
    } else {
      // Both document and month exist - UPDATE with dot notation
      final Map<String, dynamic> updateMap = {
        IHF.lastUpdated: FieldValue.serverTimestamp(),
      };

      // Handle all updates with dot notation
      for (var entry in updates.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is FieldValue) {
          // Use dot notation for FieldValue operations
          updateMap['$monthKey.$key'] = value;
        } else if (key == IHF.recentScores) {
          // Update recent scores array
          updateMap['$monthKey.$key'] = monthData[key];
          updateMap['$monthKey.${IHF.avgScore}'] = monthData[IHF.avgScore];
        } else {
          // Regular field updates
          updateMap['$monthKey.$key'] = value;
        }
      }

      batch.update(inspectorRef, updateMap);
      console('✅ Updated existing month $monthKey for inspector $inspectorId');
    }

    // Prune old months (keep last 12) - only if document exists
    if (documentExists) {
      _pruneOldMonths(batch, inspectorRef, data, monthKey);
    }
  }

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

  /// Helper: Prune old months, keeping only last 12
  void _pruneOldMonths(
    WriteBatch batch,
    DocumentReference inspectorRef,
    Map<String, dynamic> data,
    String currentMonthKey,
  ) {
    final monthKeys = data.keys
        .where((k) => RegExp(r'^\d{2}-\d{4}$').hasMatch(k))
        .toList();

    if (!monthKeys.contains(currentMonthKey)) {
      monthKeys.add(currentMonthKey);
    }

    // Sort chronologically
    monthKeys.sort((a, b) {
      final partsA = a.split('-').map(int.parse).toList();
      final partsB = b.split('-').map(int.parse).toList();
      return DateTime(
        partsA[1],
        partsA[0],
      ).compareTo(DateTime(partsB[1], partsB[0]));
    });

    // Delete months beyond the 12 most recent
    if (monthKeys.length > 12) {
      final monthsToDelete = monthKeys.take(monthKeys.length - 12);
      final deleteMap = {
        for (var oldKey in monthsToDelete) oldKey: FieldValue.delete(),
      };
      batch.update(inspectorRef, deleteMap);
    }
  }
}
