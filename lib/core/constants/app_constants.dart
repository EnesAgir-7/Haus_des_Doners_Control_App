import 'package:flutter/material.dart';

class AppConstants {
  static const inspector = "inspector";
  static const admin = "admin";
  static const pending = "pending";
  static const completed = "completed";
  static const current = "current";
  static const inProgress = "in_progress";
  static const count = "{count}";
  static const high = "high";
  static const date = "date";
  static const region = "region";
  static const medium = "medium";
  static const low = "low";
  static const all = "all";
  static const name = "name";
  static const score = "score";
  static const lastInspection = "lastInspection";
  static const dueDate = "dueDate";
  static const priority = "priority";
  static const createdAt = "createdAt";
  static const details = "details";
  static const nextInspection = "nextInspection";
  static const assigned = "assigned";
  static const available = "available";
  static const active = "active";
  static const scheduled = "scheduled";
  static const branch = "branch";
}

BoxDecoration commonDeco = BoxDecoration(
  color: const Color(0xFF212121),
  borderRadius: BorderRadius.circular(16.0),
  boxShadow: const [
    BoxShadow(color: Colors.black26, blurRadius: 10.0, offset: Offset(0, 4)),
  ],
);
