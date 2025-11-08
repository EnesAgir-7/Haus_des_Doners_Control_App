import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/screens/screen_admin_settings.dart';
import 'package:haus_des_control/Modules/inspector/screens/screen_settings.dart';
import 'package:haus_des_control/app_env.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSettings;
  final String? title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.showSettings = false,
    this.actions,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryRed,
            AppColors.primaryDark.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: title != null
            ? Text(title!)
            : Hero(
                tag: 'app_logo',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (AppEnvironment.isDev) ...[
                        const Icon(Icons.circle, color: AppColors.green),
                        const SizedBox(width: 7),
                      ],
                      Image.asset(kAppLogo, height: 32, fit: BoxFit.contain),
                    ],
                  ),
                ),
              ),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                ),
              )
            : null,
        actions:
            actions ??
            [
              if (showSettings)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => loggedInUser!.isAdmin
                            ? const ScreenAdminSettings()
                            : const ScreenSettings(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.settings_outlined,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
            ],
      ),
    );
  }
}
