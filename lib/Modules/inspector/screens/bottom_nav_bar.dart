import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/provider_bottom_nav_bar.dart';
import '../../../translations/locale_keys.g.dart';
import '../widgets/custom_toast.dart';

// ignore: must_be_immutable
class ScreenBottomNavBar extends StatelessWidget {
  ScreenBottomNavBar({super.key});
  DateTime? lastBackPressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderBottomNavBar>(
      builder: (context, controller, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (controller.selectedIndex != 0) {
              controller.onItemTapped(0);
            } else {
              final now = DateTime.now();
              if (lastBackPressed == null ||
                  now.difference(lastBackPressed!) >
                      const Duration(seconds: 2)) {
                lastBackPressed = now;
                showSnakBarr(context, LocaleKeys.click_again_to_exit.tr());
              } else {
                SystemNavigator.pop();
              }
            }
          },
          child: Scaffold(
            appBar: CustomAppBar(showSettings: true),
            body: IndexedStack(
              key: Key("stack${context.locale.languageCode}"),
              index: controller.selectedIndex,
              children: controller.screens,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.only(
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
                selectedIndex: controller.selectedIndex,
                onDestinationSelected: controller.onItemTapped,
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
                    icon: const Icon(Icons.apartment, color: Colors.white70),
                    selectedIcon: Icon(
                      Icons.apartment,
                      color: AppColors.primaryRed,
                    ),
                    label: LocaleKeys.my_branches.tr(),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.alt_route, color: Colors.white70),
                    selectedIcon: Icon(
                      Icons.alt_route,
                      color: AppColors.primaryRed,
                    ),
                    label: LocaleKeys.route.tr(),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
