import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../routes/admin_routes.dart';

class AdminNavBar extends StatelessWidget {
  const AdminNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return NavigationDrawer(
      backgroundColor: AppColors.primaryRed.withOpacity(0.1),
      selectedIndex: _getSelectedIndex(currentRoute),
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, AdminRouteNames.dashboard);
            break;
          case 1:
            Navigator.pushNamed(context, AdminRouteNames.users);
            break;
          case 2:
            Navigator.pushNamed(context, AdminRouteNames.branches);
            break;
          case 3:
            Navigator.pushNamed(context, AdminRouteNames.fleet);
            break;
          case 4:
            Navigator.pushNamed(context, AdminRouteNames.tasks);
            break;
        }
      },
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Admin Panel',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.people),
          label: Text('Users'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.store),
          label: Text('Branches'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.local_shipping),
          label: Text('Fleet'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.task),
          label: Text('Tasks'),
        ),
      ],
    );
  }

  int _getSelectedIndex(String currentRoute) {
    switch (currentRoute) {
      case AdminRouteNames.dashboard:
        return 0;
      case AdminRouteNames.users:
        return 1;
      case AdminRouteNames.branches:
        return 2;
      case AdminRouteNames.fleet:
        return 3;
      case AdminRouteNames.tasks:
        return 4;
      default:
        return 0;
    }
  }
}
