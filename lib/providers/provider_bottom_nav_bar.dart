import 'package:flutter/material.dart';
import 'package:haus_des_control/screens/user/screen_vehicle.dart';
import 'package:haus_des_control/screens/user/screen_branches.dart';
import 'package:haus_des_control/screens/user/screen_home.dart';
import 'package:haus_des_control/screens/user/screen_routes.dart';
import 'package:haus_des_control/screens/user/screen_tasks.dart';

class ProviderBottomNavBar extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  final List<Widget> screens = [
    ScreenHome(),
    ScreenBranches(),
    ScreenRoutes(),
    ScreenVehicle(),
    ScreenTasks(),
  ];

  void onItemTapped(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
