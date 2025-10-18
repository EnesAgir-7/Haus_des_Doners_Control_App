import 'package:flutter/material.dart';

import '../admin/screens/screen_admin_branches.dart';
import '../admin/screens/screen_admin_fleet.dart';
import '../admin/screens/screen_admin_main.dart';
import '../admin/screens/screen_admin_tasks.dart';
import '../admin/screens/screen_admin_users.dart';
import '../layouts/bottom_nav_bar.dart';
import '../screens/screen_auth.dart';
import '../screens/user/screen_submit_report.dart';
import '../screens/user/screen_vehicle.dart';
import '../screens/user/screen_branches.dart';
import '../screens/user/screen_home.dart';
import '../screens/user/screen_routes.dart';
import '../screens/user/screen_tasks.dart';

/// Contains all route names as constants
class RouteNames {
  // User routes
  static const String panel = '/panel';
  static const String subsidiaries = '/subsidiaries';
  static const String control = '/control';
  static const String route = '/route';
  static const String fleet = '/fleet';
  static const String tasks = '/tasks';
  static const String auth = '/auth';
  static const String mainLayout = '/mainLayout';

  // Admin routes
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminBranches = '/admin/branches';
  static const String adminFleet = '/admin/fleet';
  static const String adminTasks = '/admin/tasks';
}

/// Route generator class for the application
class AppRouter {
  static Map<String, Widget Function(BuildContext)> routes = {
    // User routes
    RouteNames.panel: (context) => const ScreenHome(),
    RouteNames.subsidiaries: (context) => const ScreenBranches(),
    RouteNames.control: (context) => const ScreenSubmitReport(),
    RouteNames.route: (context) => const ScreenRoutes(),
    RouteNames.fleet: (context) => const ScreenVehicle(),
    RouteNames.tasks: (context) => ScreenTasks(),
    RouteNames.auth: (context) => const ScreenAuth(),
    RouteNames.mainLayout: (context) => ScreenBottomNavBar(),

    // Admin routes
    RouteNames.admin: (context) => const AdminMainScreen(),
    RouteNames.adminUsers: (context) => const AdminUsersScreen(),
    RouteNames.adminBranches: (context) => const AdminBranchesScreen(),
    RouteNames.adminFleet: (context) => const AdminFleetScreen(),
    RouteNames.adminTasks: (context) => const ScreenAdminTasks(),
  };
}
