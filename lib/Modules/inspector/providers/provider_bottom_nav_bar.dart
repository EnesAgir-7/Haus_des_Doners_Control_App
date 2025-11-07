import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/screens/screen_branches.dart';
import 'package:haus_des_control/Modules/inspector/screens/screen_routes.dart';
import 'package:haus_des_control/Modules/inspector/screens/screen_tasks.dart';
import 'package:haus_des_control/common_services/remote_config_service.dart';

import '../screens/screen_home.dart';
import '../screens/screen_home_old.dart';
import '../screens/screen_vehicles_list.dart';

class ProviderBottomNavBar extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  final List<Widget> screens = [
    RemoteConfigService().useOldHome ? ScreenHomeOld() : ScreenHome(),
    ScreenBranches(),
    ScreenRoutes(),
    ScreenVehiclesList(),
    ScreenTasks(),
  ];

  void onItemTapped(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
