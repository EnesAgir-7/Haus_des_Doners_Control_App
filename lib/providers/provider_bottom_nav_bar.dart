import 'package:flutter/material.dart';
import 'package:haus_des_control/screens/user/fleet_page.dart';
import 'package:haus_des_control/screens/user/my_branches_page.dart';
import 'package:haus_des_control/screens/user/panel_page.dart';
import 'package:haus_des_control/screens/user/route_page.dart';
import 'package:haus_des_control/screens/user/tasks_page.dart';

class ProviderBottomNavBar extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  final List<Widget> screens = [
    PanelPage(),
    BranchesPage(),
    RoutePage(),
    FleetPage(),
    TasksPage(),
  ];

  void onItemTapped(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
