import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/provider_bottom_nav_bar.dart';
import '../translations/locale_keys.g.dart';
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
                showSnakBarr(context, "Click again to exit");
              } else {
                SystemNavigator.pop();
              }
            }
          },
          child: Scaffold(
            appBar: CustomAppBar(),
            body: IndexedStack(
              key: Key("stack${context.locale.languageCode}"),
              index: controller.selectedIndex,
              children: controller.screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: controller.selectedIndex,
              onTap: controller.onItemTapped,
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
                  icon: const Icon(Icons.apartment),
                  label: LocaleKeys.my_branches.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.alt_route),
                  label: LocaleKeys.route.tr(),
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
          ),
        );
      },
    );
  }
}
