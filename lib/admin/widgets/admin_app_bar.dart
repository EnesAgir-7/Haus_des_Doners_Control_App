import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/provider_auth.dart';
import '../../widgets/language_button.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryRed,
      child: SafeArea(
        child: Column(
          children: [
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
          ],
        ),
      ),
    );
  }
}
