import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/screens/screen_admin_branches.dart';
import 'package:haus_des_control/Modules/admin/screens/screen_admin_vehicle.dart';
import 'package:haus_des_control/Modules/admin/screens/screen_admin_tasks.dart';
import 'package:haus_des_control/Modules/admin/screens/screen_admin_users.dart';

import '../screens/screen_admin_home.dart';
import '../screens/screen_admin_settings.dart';

class AdminBottomNavProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  final List<Widget> screens = [
    ScreenAdminHome(),
    ScreenAdminUsers(),
    ScreenAdminBranches(),
    ScreenAdminVehicle(),
    ScreenAdminTasks(),
    ScreenAdminSettings(),
  ];

  void onItemTapped(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
