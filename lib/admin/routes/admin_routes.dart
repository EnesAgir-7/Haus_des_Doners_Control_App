import 'package:flutter/material.dart';

import '../screens/screen_admin_dashboard.dart';
import '../screens/screen_admin_users.dart';
import '../screens/screen_admin_branches.dart';
import '../screens/screen_admin_fleet.dart';
import '../screens/screen_admin_tasks.dart';

/// Admin route names as constants
class AdminRouteNames {
  static const String dashboard = '/admin';
  static const String users = '/admin/users';
  static const String branches = '/admin/branches';
  static const String fleet = '/admin/fleet';
  static const String tasks = '/admin/tasks';
}

/// Admin route generator class
class AdminRouter {
  static Map<String, Widget Function(BuildContext)> routes = {
    AdminRouteNames.dashboard: (context) => AdminDashboard(),
    AdminRouteNames.users: (context) => const AdminUsersScreen(),
    AdminRouteNames.branches: (context) => const AdminBranchesScreen(),
    AdminRouteNames.fleet: (context) => const AdminFleetScreen(),
    AdminRouteNames.tasks: (context) => const AdminTasksScreen(),
  };
}
