import 'package:flutter/material.dart';

import '../admin/screens/screen_admin_branches.dart';
import '../admin/screens/screen_admin_dashboard.dart';
import '../admin/screens/screen_admin_fleet.dart';
import '../admin/screens/screen_admin_tasks.dart';
import '../admin/screens/screen_admin_users.dart';
import '../layouts/bottom_nav_bar.dart';
import '../screens/screen_auth.dart';
import '../screens/user/control_page_new.dart';
import '../screens/user/fleet_page.dart';
import '../screens/user/my_branches_page.dart';
import '../screens/user/panel_page.dart';
import '../screens/user/route_page.dart';
import '../screens/user/tasks_page.dart';

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
    RouteNames.panel: (context) => const PanelPage(),
    RouteNames.subsidiaries: (context) => const BranchesPage(),
    RouteNames.control: (context) => const ControlPage(),
    RouteNames.route: (context) => RoutePage(),
    RouteNames.fleet: (context) => const FleetPage(),
    RouteNames.tasks: (context) => TasksPage(),
    RouteNames.auth: (context) => ScreenAuth(),
    RouteNames.mainLayout: (context) => const ScreenBottomNavBar(),

    // Admin routes
    RouteNames.admin: (context) => AdminDashboard(),
    RouteNames.adminUsers: (context) => const AdminUsersScreen(),
    RouteNames.adminBranches: (context) => const AdminBranchesScreen(),
    RouteNames.adminFleet: (context) => const AdminFleetScreen(),
    RouteNames.adminTasks: (context) => const AdminTasksScreen(),
  };
}
