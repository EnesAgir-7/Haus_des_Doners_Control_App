// lib/screens/admin/screen_admin_settings.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/app_button.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/language_button.dart';
import '../providers/provider_auth_new.dart';

class ScreenSettings extends StatelessWidget {
  const ScreenSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderAuth>(
      builder: (context, authProvider, child) {
        return Scaffold(
          key: Key('settingsScreen${context.locale.languageCode}'),
          appBar: const CustomAppBar(),
          persistentFooterDecoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          persistentFooterButtons: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AppButton(
                text: LocaleKeys.logout.tr(),
                isLoading: authProvider.isLoading,
                onPressed: authProvider.isLoading
                    ? null
                    : () => _handleLogout(context, authProvider),
              ),
            ),
          ],
          body: Container(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildSectionTitle(context, LocaleKeys.change_language.tr()),
                  const SizedBox(height: 16),
                  const LanguageButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    ProviderAuth authProvider,
  ) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LocaleKeys.logout.tr()),
        content: Text(LocaleKeys.confirmLogoutMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryRed),
            child: Text(LocaleKeys.logout.tr()),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await authProvider.logout(context: context);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        showSnakBarr(context, e.toString());
      }
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.settings, color: Colors.lightBlueAccent),
        const SizedBox(width: 6),
        Text(
          loggedInUser != null && loggedInUser!.isAdmin
              ? LocaleKeys.adminSettings.tr()
              : LocaleKeys.settings_label.tr(),
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
