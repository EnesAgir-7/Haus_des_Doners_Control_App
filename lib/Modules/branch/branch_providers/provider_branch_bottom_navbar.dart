import 'package:flutter/material.dart';

import '../screens/branch_screen_home.dart';

class ProviderBranchBottomNavBar extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  final List<Widget> screens = [
    const ScreenBranchDashboard(),
    const SizedBox(),
    const SizedBox(),
    const SizedBox(),
    const SizedBox(),
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
