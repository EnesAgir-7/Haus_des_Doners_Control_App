import 'package:cloud_firestore/cloud_firestore.dart';
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
    if (inspectorDoc.exists) {
      data = inspectorDoc.data() ?? {};
    }

    final currentMonthData =
        (data[monthKey] as Map<String, dynamic>?) ?? defaultModel.toMap();

    // Start building update map
    final Map<String, dynamic> updateMap = {
      IHF.lastUpdated: FieldValue.serverTimestamp(),
      '$monthKey.${IHF.inspectorId}': inspectorId,
      '$monthKey.${IHF.totalInspections}':
          currentMonthData[IHF.totalInspections] ??
          defaultModel.totalInspections,
      '$monthKey.${IHF.avgScore}':
          currentMonthData[IHF.avgScore] ?? defaultModel.avgScore,
      '$monthKey.${IHF.tasksTotal}':
          currentMonthData[IHF.tasksTotal] ?? defaultModel.tasksTotal,
      '$monthKey.${IHF.tasksCompleted}':
          currentMonthData[IHF.tasksCompleted] ?? defaultModel.tasksCompleted,
      '$monthKey.${IHF.recentScores}':
          currentMonthData[IHF.recentScores] ?? defaultModel.recentScores,
      '$monthKey.${IHF.vehicleIds}':
          currentMonthData[IHF.vehicleIds] ?? defaultModel.vehicleIds,
      '$monthKey.${IHF.branchesIds}':
          currentMonthData[IHF.branchesIds] ?? defaultModel.branchesIds,
    };

    // Apply updates
    for (var entry in updates.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key == IHF.recentScores && value is List) {
        final existingScores =
            (currentMonthData[IHF.recentScores] as List<dynamic>? ?? [])
                .cast<String>();
        final newScores = value.cast<String>();
        final allScores = [...existingScores, ...newScores];
        final limitedScores = allScores.length > 10
            ? allScores.sublist(allScores.length - 10)
            : allScores;

        updateMap['$monthKey.$key'] = limitedScores;

        // Calculate avgScore
        final scores = limitedScores
            .map((s) => double.tryParse(s) ?? 0.0)
            .where((s) => s > 0)
            .toList();
        if (scores.isNotEmpty) {
          final avgScore = scores.reduce((a, b) => a + b) / scores.length;
          updateMap['$monthKey.${IHF.avgScore}'] = double.parse(
            avgScore.toStringAsFixed(2),
          );
        }
      } else {
        updateMap['$monthKey.$key'] = value;
      }
    }

    final scoresList =
        (updateMap['$monthKey.${IHF.recentScores}'] as List<dynamic>? ?? [])
            .cast<String>();
    final numericScores = scoresList
        .map((s) => double.tryParse(s) ?? 0.0)
        .where((s) => s > 0)
        .toList();
    updateMap['$monthKey.${IHF.avgScore}'] = numericScores.isNotEmpty
        ? double.parse(
            (numericScores.reduce((a, b) => a + b) / numericScores.length)
                .toStringAsFixed(2),
          )
        : 0.0;

    if (inspectorDoc.exists) {
      batch.update(inspectorRef, updateMap);
    } else {
      // Create new doc with all fields
      batch.set(inspectorRef, {
        IHF.inspectorId: inspectorId,
        IHF.lastUpdated: FieldValue.serverTimestamp(),
        monthKey: updateMap[monthKey] ?? updateMap,
      });
    }

    // Prune old months (keep last 12)
    _pruneOldMonths(batch, inspectorRef, data, monthKey);
  }

  // /// Helper: Build initial month data for new documents
  // Map<String, dynamic> _buildInitialMonthData(
  //   String inspectorId,
  //   Map<String, dynamic> updates,
  // ) {
  //   final monthData = <String, dynamic>{
  //     IHF.inspectorId: inspectorId,
  //     IHF.totalInspections: "0",
  //     IHF.avgScore: "0.0",
  //     IHF.tasksTotal: "0",
  //     IHF.tasksCompleted: "0",
  //     IHF.recentScores: <String>[],
  //     IHF.vehicleIds: <String>[],
  //     IHF.branchesIds: <String>[],
  //   };

  //   // Apply updates, handling FieldValue specially
  //   for (var entry in updates.entries) {
  //     final key = entry.key;
  //     final value = entry.value;

  //     if (value is FieldValue) {
  //       // For FieldValue in new docs, set initial value of 1 or empty array
  //       if (key == IHF.totalInspections ||
  //           key == IHF.tasksCompleted ||
  //           key == IHF.tasksTotal) {
  //         monthData[key] = 1;
  //       } else if (key == IHF.branchesIds || key == IHF.vehicleIds) {
  //         monthData[key] = [];
  //       }
  //     } else if (key == IHF.recentScores && value is List) {
  //       // Handle scores with average calculation
  //       final scores = value.cast<String>();
  //       monthData[IHF.recentScores] = scores;

  //       if (scores.isNotEmpty) {
  //         final numScores = scores
  //             .map((s) => double.tryParse(s) ?? 0.0)
  //             .where((s) => s > 0)
  //             .toList();
  //         if (numScores.isNotEmpty) {
  //           final avgScore =
  //               numScores.reduce((a, b) => a + b) / numScores.length;
  //           monthData[IHF.avgScore] = double.parse(avgScore.toStringAsFixed(2));
  //         }
  //       }
  //     } else {
  //       // Direct values
  //       monthData[key] = value;
  //     }
  //   }

  //   return monthData;
  // }

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
