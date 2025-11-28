import 'package:flutter/material.dart';

import '../screens/branch_dashboard_tab.dart';
import '../screens/branch_screen_details.dart';

class ProviderBranchBottomNavBar extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  final List<Widget> screens = [
    const BranchDetailsTab(),
    const ScreenBranchDashboardTab(),
    const Center(child: SizedBox.shrink()),
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
