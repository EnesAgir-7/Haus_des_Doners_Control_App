import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../widgets/admin_app_bar.dart';

import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../translations/locale_keys.g.dart';

class AdminBottomNavBar extends StatefulWidget {
  const AdminBottomNavBar({super.key});

  @override
  State<AdminBottomNavBar> createState() => _AdminBottomNavBarState();
}

class _AdminBottomNavBarState extends State<AdminBottomNavBar> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // build all screens once so their state is preserved
    _screens = [
      AppRouter.routes[RouteNames.admin]!(context),
      AppRouter.routes[RouteNames.adminUsers]!(context),
      AppRouter.routes[RouteNames.adminBranches]!(context),
      AppRouter.routes[RouteNames.adminFleet]!(context),
      AppRouter.routes[RouteNames.adminTasks]!(context),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: LocaleKeys.panel.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.apartment),
            label: LocaleKeys.my_branches.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.car_rental),
            label: LocaleKeys.fleet.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.task),
            label: LocaleKeys.tasks.tr(),
          ),
        ],
      ),
    );
  }
}
