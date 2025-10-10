import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class ProviderBottomNavBar extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  late final List<Widget> screens;

  bool _isInitialized = false;

  /// Initialize all screens once (preserve their state)
  void initScreens(BuildContext context) {
    if (_isInitialized) return;
    _isInitialized = true;

    screens = [
      AppRouter.routes[RouteNames.panel]!(context),
      AppRouter.routes[RouteNames.subsidiaries]!(context),
      AppRouter.routes[RouteNames.route]!(context),
      AppRouter.routes[RouteNames.fleet]!(context),
      AppRouter.routes[RouteNames.tasks]!(context),
    ];
  }

  void onItemTapped(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
