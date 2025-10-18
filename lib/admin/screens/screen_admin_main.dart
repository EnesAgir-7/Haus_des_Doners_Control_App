import 'package:flutter/material.dart';
import 'package:haus_des_control/admin/screens/screen_admin_branches.dart';
import 'package:haus_des_control/admin/screens/screen_admin_dashboard.dart';
import 'package:haus_des_control/admin/screens/screen_admin_fleet.dart';
import 'package:haus_des_control/admin/screens/screen_admin_tasks.dart';
import 'package:haus_des_control/admin/screens/screen_admin_users.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboard(),
    const AdminUsersScreen(),
    const AdminBranchesScreen(),
    const AdminFleetScreen(),
    const ScreenAdminTasks(),
  ];

  // selection is controlled by the parent `AdminBottomNavBar` when used
  // inside that layout. Keep state here in case this widget is used
  // standalone, but don't expose a separate handler.

  @override
  Widget build(BuildContext context) {
    // This screen is used as a content widget inside the top-level
    // `AdminBottomNavBar` scaffold. Avoid providing a Scaffold/AppBar/
    // BottomNavigationBar here to prevent duplicate bars.
    return Container(
      color: AppColors.primaryDark,
      child: _screens[_selectedIndex],
    );
  }
}
