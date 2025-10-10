import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haus_des_control/widgets/custom_app_bar.dart';

import '../core/constants/app_colors.dart';
import '../providers/provider_bottom_nav_bar.dart';
import '../translations/locale_keys.g.dart';

class ScreenBottomNavBar extends StatelessWidget {
  const ScreenBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ProviderBottomNavBar>();
    controller.initScreens(context);

    return Consumer<ProviderBottomNavBar>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: CustomAppBar(),
          body: IndexedStack(
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
        );
      },
    );
  }
}
