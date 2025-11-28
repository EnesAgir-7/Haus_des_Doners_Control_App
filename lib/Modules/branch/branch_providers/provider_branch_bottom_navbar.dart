import 'package:flutter/material.dart';

import '../screens/branch_dashboard_tab.dart';
import '../screens/branch_screen_details.dart';
import '../screens/branch_screen_inspections.dart';

class ProviderBranchBottomNavBar extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  final List<Widget> screens = [
    const BranchDetailsTab(),
    const ScreenBranchInspections(),
    const ScreenBranchDashboardTab(),
    //   BranchInfoScreen(),
    // BranchReportsScreen(),
    // BranchNotificationsScreen(),
    // BranchDocumentsScreen(),
    // BranchTrainingScreen(),
  ];

  void onItemTapped(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
