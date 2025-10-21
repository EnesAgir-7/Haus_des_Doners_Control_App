import '../../models/user_model.dart';

class Collections {
  static const String branches = 'branches';
  static const String inspectionTemplates = 'inspectionTemplates';
  static const String inspections = 'inspections';
  static const String routes = 'routes';
  static const String tasks = 'tasks';
  static const String users = 'users';
  static const String vehicles = 'vehicles';
  static const String inspectors = 'inspectors';
  static const String admins = 'admins';
  static const String inspectorStats = 'inspector_stats';
}

class AppConstants {
  static const inspector = "inspector";
  static const admin = "admin";
  static const pending = "pending";
  static const completed = "completed";
  static const current = "current";
  static const inProgress = "in_progress";
  static const count = "{count}";
  static const high = "high";
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
}

UserModel? loggedInUser;
