/// Defines all the routes available in the application.

import 'package:flutter/material.dart';
import 'package:haus_des_control/layouts/main_layout.dart';
import '../screens/screen_auth.dart';
import '../screens/user/control_page.dart';
import '../screens/user/subsidiaries_page.dart';
import '../screens/user/panel_page.dart';
import '../screens/user/route_page.dart';
import '../screens/user/fleet_page.dart';
import '../screens/user/tasks_page.dart';

/// Contains all route names as constants
class RouteNames {
  static const String panel = '/panel';
  static const String subsidiaries = '/subsidiaries';
  static const String control = '/control';
  static const String route = '/route';
  static const String fleet = '/fleet';
  static const String tasks = '/tasks';
  static const String auth = '/auth';
  static const String mainLayout = '/mainLayout';
}

/// Route generator class for the application
class AppRouter {
  static Map<String, Widget Function(BuildContext)> routes = {
    RouteNames.panel: (context) => const PanelPage(),
    RouteNames.subsidiaries: (context) => const SubsidiariesPage(),
    RouteNames.control: (context) => const ControlPage(),
    RouteNames.route: (context) => RoutePage(),
    RouteNames.fleet: (context) => const FleetPage(),
    RouteNames.tasks: (context) => const TasksPage(),
    RouteNames.auth: (context) => const ScreenAuth(),
    RouteNames.mainLayout: (context) => const MainLayout(),
  };
}
