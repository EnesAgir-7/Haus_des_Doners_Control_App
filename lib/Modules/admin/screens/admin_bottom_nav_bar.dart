import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/Modules/admin/widgets/admin_app_bar.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../admin_providers/provider_admin_bottombar.dart';

// ignore: must_be_immutable
class AdminBottomNavBar extends StatelessWidget {
  AdminBottomNavBar({super.key});

  DateTime? lastBackPressed;
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminBottomNavProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (provider.selectedIndex != 0) {
              provider.onItemTapped(0);
            } else {
              final now = DateTime.now();
              if (lastBackPressed == null ||
                  now.difference(lastBackPressed!) >
                      const Duration(seconds: 2)) {
                lastBackPressed = now;
                showSnakBarr(context, "Click again to exit");
              } else {
                SystemNavigator.pop();
              }
            }
          },
          child: Scaffold(
            appBar: const AdminAppBar(),
            body: IndexedStack(
              key: Key("admin_stack_${context.locale.languageCode}"),
              index: provider.selectedIndex,
              children: provider.screens,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: provider.selectedIndex,
                onDestinationSelected: provider.onItemTapped,
                backgroundColor: Colors.transparent,
                elevation: 4,
                indicatorColor: AppColors.primaryRed.withValues(alpha: 0.15),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                maintainBottomViewPadding: true,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.dashboard, color: Colors.white70),
                    selectedIcon: Icon(
                      Icons.dashboard,
                      color: AppColors.primaryRed,
                    ),
                    label: LocaleKeys.panel.tr(),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.people, color: Colors.white70),
                    selectedIcon: Icon(
                      Icons.people,
                      color: AppColors.primaryRed,
                    ),
                    label: "Users",
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.apartment, color: Colors.white70),
                    selectedIcon: Icon(
                      Icons.apartment,
                      color: AppColors.primaryRed,
                    ),
                    label: "Branches",
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.car_rental, color: Colors.white70),
                    selectedIcon: Icon(
                      Icons.car_rental,
                      color: AppColors.primaryRed,
                    ),
                    label: LocaleKeys.fleet.tr(),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.task, color: Colors.white70),
                    selectedIcon: Icon(Icons.task, color: AppColors.primaryRed),
                    label: LocaleKeys.tasks.tr(),
                  ),

                  NavigationDestination(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    selectedIcon: Icon(
                      Icons.settings,
                      color: AppColors.primaryRed,
                    ),
                    label: "Settings",
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
