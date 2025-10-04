import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/console.dart';
import '../models/route_model.dart';

class RouteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'routes';

  // Get today's route for inspectorimport 'package:cloud_firestore/cloud_firestore.dart'; // Make sure you have this import
  Future<RouteModel?> getTodaysRoute(String userId) async {
    try {
      final docSnap = await _db.collection('routes').doc(userId).get();

      if (!docSnap.exists) {
        print("No route found for user $userId.");
        return null;
      }

      return RouteModel.fromFirestore(docSnap);
    } catch (e) {
      print("Error fetching today's route for user $userId: $e");
      return null;
    }
  }

  // Future<RouteModel?> getTodaysRoute(String inspectorId) async {
  //   try {
  //     // 1. Define the start and end of the day in UTC for consistent queries
  //     final now = DateTime.now();
  //     final startOfDay = DateTime.utc(
  //       now.year,
  //       now.month,
  //       now.day,
  //     ); // Midnight today, UTC
  //     final endOfDay = DateTime.utc(
  //       now.year,
  //       now.month,
  //       now.day + 1,
  //     ); // Midnight tomorrow, UTC

  //     final snapshot = await _db
  //         .collection(_collection)
  //         .where('inspectorId', isEqualTo: inspectorId)
  //         // 2. Query for a date within the range
  //         .where('date', isGreaterThanOrEqualTo: startOfDay)
  //         .where('date', isLessThan: endOfDay)
  //         .limit(1)
  //         .get();

  //     if (snapshot.docs.isEmpty) {
  //       print("No route found for today.");
  //       return null;
  //     }
  //     return RouteModel.fromFirestore(snapshot.docs.first);
  //   } catch (e) {
  //     console('Error getting today\'s route: $e');
  //     return null;
  //   }
  // }

  // Stream today's route (real-time)
  Stream<RouteModel?> streamTodaysRoute(String inspectorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _db
        .collection(_collection)
        .where('inspectorId', isEqualTo: inspectorId)
        .where('date', isEqualTo: startOfDay)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return RouteModel.fromFirestore(snapshot.docs.first);
        });
  }

  // Get route by date
  Future<RouteModel?> getRouteByDate(String inspectorId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);

      final snapshot = await _db
          .collection(_collection)
          .where('inspectorId', isEqualTo: inspectorId)
          .where('date', isEqualTo: startOfDay)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return RouteModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      console('Error getting route by date: $e');
      return null;
    }
  }

  // Get routes by inspector (date range)
  Future<List<RouteModel>> getRoutesByInspector(
    String inspectorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _db
          .collection(_collection)
          .where('inspectorId', isEqualTo: inspectorId);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.orderBy('date', descending: true).get();

      return snapshot.docs.map((doc) => RouteModel.fromFirestore(doc)).toList();
    } catch (e) {
      console('Error getting routes by inspector: $e');
      return [];
    }
  }

  // Create route
  Future<String> createRoute(RouteModel route) async {
    try {
      final docRef = await _db.collection(_collection).add(route.toMap());
      return docRef.id;
    } catch (e) {
      console('Error creating route: $e');
      rethrow;
    }
  }

  // Update route
  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection(_collection).doc(routeId).update(data);
    } catch (e) {
      console('Error updating route: $e');
      rethrow;
    }
  }

  // Update stop status
  Future<void> updateStopStatus(
    String routeId,
    int stopIndex,
    String newStatus,
  ) async {
    try {
      final doc = await _db.collection(_collection).doc(routeId).get();
      if (!doc.exists) throw Exception('Route not found');

      final route = RouteModel.fromFirestore(doc);
      if (stopIndex >= route.stops.length) {
        throw Exception('Invalid stop index');
      }

      route.stops[stopIndex] = RouteStopModel(
        timeSlot: route.stops[stopIndex].timeSlot,
        branchId: route.stops[stopIndex].branchId,
        branchName: route.stops[stopIndex].branchName,
        status: newStatus,
        inspectionId: route.stops[stopIndex].inspectionId,
        order: route.stops[stopIndex].order,
      );

      await _db.collection(_collection).doc(routeId).update({
        'stops': route.stops.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console('Error updating stop status: $e');
      rethrow;
    }
  }
}
