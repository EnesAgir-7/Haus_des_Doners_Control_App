import 'package:flutter/material.dart';

import '../screens/branch_screen_more.dart';
import '../screens/branch_screen_details.dart';
import '../screens/branch_screen_inspections.dart';

class ProviderBranchBottomNavBar extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  final List<Widget> screens = [
    const BranchScreenDetails(),
    const BranchScreenInspections(),
    const BranchScreenMore(),
  ];

  void onItemTapped(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
