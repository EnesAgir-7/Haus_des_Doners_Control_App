import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';

class AdminNavBar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onRouteSelected;

  const AdminNavBar({
    super.key,
    required this.currentRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.primaryRed.withOpacity(0.1),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryRed.withOpacity(0.2),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: AppColors.white),
                SizedBox(width: 12),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          // Navigation links
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavLink(
                  context,
                  'Dashboard',
                  RouteNames.admin,
                  Icons.dashboard,
                ),
                _buildNavLink(
                  context,
                  'Users',
                  RouteNames.adminUsers,
                  Icons.people,
                ),
                _buildNavLink(
                  context,
                  'Branches',
                  RouteNames.adminBranches,
                  Icons.store,
                ),
                _buildNavLink(
                  context,
                  'Fleet',
                  RouteNames.adminFleet,
                  Icons.local_shipping,
                ),
                _buildNavLink(
                  context,
                  'Tasks',
                  RouteNames.adminTasks,
                  Icons.task,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(
    BuildContext context,
    String title,
    String route,
    IconData icon,
  ) {
    final bool isCurrentRoute = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isCurrentRoute ? AppColors.primaryRed : AppColors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isCurrentRoute ? AppColors.primaryRed : AppColors.white,
          fontWeight: isCurrentRoute ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => onRouteSelected(route),
      tileColor: isCurrentRoute
          ? Colors.white.withOpacity(0.1)
          : Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }
}
