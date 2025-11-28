import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_toast.dart';
import '../branch_providers/provider_branch_bottom_navbar.dart';

// ignore: must_be_immutable
class BranchScreenBottomNavBar extends StatelessWidget {
  BranchScreenBottomNavBar({super.key});
  DateTime? lastBackPressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderBranchBottomNavBar>(
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
            appBar: const CustomAppBar(showSettings: true),
            body: IndexedStack(
              key: Key("branchstack${context.locale.languageCode}"),
              index: controller.selectedIndex,
              children: controller.screens,
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
                selectedIndex: controller.selectedIndex,
                onDestinationSelected: controller.onItemTapped,
                backgroundColor: Colors.transparent,
                elevation: 4,
                indicatorColor: AppColors.primaryRed.withValues(alpha: 0.15),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

                destinations: const [
                  // 0 - Branch Info
                  NavigationDestination(
                    icon: Icon(Icons.home, color: Colors.white70),
                    selectedIcon: Icon(Icons.home, color: AppColors.primaryRed),
                    label: "Branch Info",
                  ),

                  // 1 - Control Reports
                  NavigationDestination(
                    icon: Icon(Icons.dashboard, color: Colors.white70),
                    selectedIcon: Icon(
                      Icons.dashboard,
                      color: AppColors.primaryRed,
                    ),
                    label: "Branch Dashboard",
                  ),

                  // 2 - Notifications (letters, announcements)
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz, color: Colors.white70),
                    selectedIcon: Icon(
                      Icons.more_horiz,
                      color: AppColors.primaryRed,
                    ),
                    label: "More",
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
