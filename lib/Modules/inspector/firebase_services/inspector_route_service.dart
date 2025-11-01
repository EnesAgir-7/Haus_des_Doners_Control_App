import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';

import '../../../core/console.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/route_model.dart';

class InspectorRouteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = Collections.routes;

  Stream<RouteModel?> getAllRoutesStream(String userId) {
    return _db.collection(_collection).doc(userId).snapshots().map((docSnap) {
      if (!docSnap.exists) {
        print("No route found for user $userId.");
        return null;
      }
      return RouteModel.fromFirestore(docSnap);
    });
  }

  // Get route by date
  Future<RouteModel?> getRouteByDate(String inspectorId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);

      final snapshot = await _db
          .collection(_collection)
          .where(RouteFields.inspectorId, isEqualTo: inspectorId)
          .where(RouteFields.date, isEqualTo: startOfDay)
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
          .where(RouteFields.inspectorId, isEqualTo: inspectorId);

      if (startDate != null) {
        query = query.where(
          RouteFields.date,
          isGreaterThanOrEqualTo: startDate,
        );
      }
      if (endDate != null) {
        query = query.where(RouteFields.date, isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query
          .orderBy(RouteFields.date, descending: true)
          .get();

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
      data[RouteFields.updatedAt] = FieldValue.serverTimestamp();
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
      if (!doc.exists) throw Exception(LocaleKeys.noRouteFound.tr());

      final route = RouteModel.fromFirestore(doc);
      if (stopIndex >= route.stops.length) {
        throw Exception('Invalid stop index');
      }

      route.stops[stopIndex] = RouteStopModel(
        branchTemplateId: route.stops[stopIndex].branchTemplateId,
        timeSlot: route.stops[stopIndex].timeSlot,
        branchId: route.stops[stopIndex].branchId,
        branchName: route.stops[stopIndex].branchName,
        status: newStatus,
        order: route.stops[stopIndex].order,
      );

      await _db.collection(_collection).doc(routeId).update({
        RouteFields.stops: route.stops.map((s) => s.toMap()).toList(),
        RouteFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console('Error updating stop status: $e');
      rethrow;
    }
  }
}
