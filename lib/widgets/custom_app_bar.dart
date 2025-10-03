import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../translations/locale_keys.g.dart';
import '../providers/provider_auth.dart';
import 'language_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;
  final Function(String) onRouteSelected;

  const CustomAppBar({
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
                    child: Image.asset(kAppLogo, height: 36),
                  ),
                ),

                Row(
                  children: [
                    LanguageButton(),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        // Logout via ProviderAuth
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
              color: AppColors.primaryDark,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildNavLink(
                      context,
                      LocaleKeys.panel.tr(),
                      RouteNames.panel,
                    ),
                    _buildNavLink(
                      context,
                      LocaleKeys.my_branches.tr(),
                      RouteNames.subsidiaries,
                    ),
                    _buildNavLink(
                      context,
                      LocaleKeys.control.tr(),
                      RouteNames.control,
                    ),
                    _buildNavLink(
                      context,
                      LocaleKeys.route.tr(),
                      RouteNames.route,
                    ),
                    _buildNavLink(
                      context,
                      LocaleKeys.file.tr(),
                      RouteNames.fleet,
                    ),
                    _buildNavLink(
                      context,
                      LocaleKeys.tasks.tr(),
                      RouteNames.tasks,
                    ),
                  ],
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
