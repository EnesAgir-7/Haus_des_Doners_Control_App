import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/provider_auth.dart';
import '../../widgets/language_button.dart';
import '../routes/admin_routes.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;
  final Function(String) onRouteSelected;

  const AdminAppBar({
    super.key,
    required this.currentRoute,
    required this.onRouteSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryRed,
      child: SafeArea(
        child: Column(
          children: [
            // Top row with logo, language button, and logout button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Image.asset(kAppLogo, height: 36),
                        const SizedBox(width: 12),
                        const Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    LanguageButton(),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        context.read<ProviderAuth>().logout();
                      },
                      icon: const Icon(Icons.logout, color: AppColors.white),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ],
            ),

            // Navigation row
            Container(
              width: MediaQuery.of(context).size.width,
              color: AppColors.primaryDark,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavLink(
                        context,
                        'Dashboard',
                        AdminRouteNames.dashboard,
                      ),
                      _buildNavLink(context, 'Users', AdminRouteNames.users),
                      _buildNavLink(
                        context,
                        'Branches',
                        AdminRouteNames.branches,
                      ),
                      _buildNavLink(context, 'Fleet', AdminRouteNames.fleet),
                      _buildNavLink(context, 'Tasks', AdminRouteNames.tasks),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String title, String route) {
    final bool isCurrentRoute = currentRoute == route;

    return TextButton(
      onPressed: () => onRouteSelected(route),
      style: TextButton.styleFrom(
        backgroundColor: isCurrentRoute
            ? AppColors.primaryRed
            : Colors.transparent,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        textStyle: const TextStyle(fontSize: 14),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(title),
    );
  }
}
