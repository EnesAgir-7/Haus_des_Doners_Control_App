import 'package:flutter/material.dart';

class ProviderBranchBottomNavBar extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  final List<Widget> screens = [
    const SizedBox(), 
    const SizedBox(), 
    const SizedBox(), 
    const SizedBox(), 
    const SizedBox(), 
  ];

  void onItemTapped(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
