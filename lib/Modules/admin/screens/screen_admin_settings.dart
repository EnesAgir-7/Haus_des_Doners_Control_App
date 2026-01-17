// lib/screens/admin/screen_admin_settings.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/screens/screen_admin_other_users.dart';
import 'package:haus_des_control/Modules/inspector/widgets/app_button.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:provider/provider.dart';

import '../../../common_services/app_update_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/providers/provider_auth_new.dart';
import '../../inspector/widgets/custom_toast.dart';
import '../../inspector/widgets/language_button.dart';
import 'screen_admin_templates.dart';

class ScreenAdminSettings extends StatelessWidget {
  const ScreenAdminSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderAuth>(
      builder: (context, authProvider, child) {
        return Scaffold(
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
                  _buildSectionTitle(
                    context,
                    LocaleKeys.inspectionManagement.tr(),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.description,
                    title: LocaleKeys.inspectionQuestionnaire.tr(),
                    subtitle: LocaleKeys.createModifyDeleteForms.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ScreenAdminQuestionnaires(),
                        ),
                      );
                    },
                    color: AppColors.primaryRed,
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.admin_panel_settings,
                    title: LocaleKeys.manageAdmins.tr(),
                    subtitle: LocaleKeys.addEditRemoveAdmins.tr(),
                    color: AppColors.primaryRed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScreenAdminOtherUser(
                            role: AppConstants.admin,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.supervised_user_circle,
                    title: LocaleKeys.manage_branch_users.tr(),
                    subtitle: LocaleKeys.manage_branch_users_subtitle.tr(),
                    color: AppColors.primaryRed,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScreenAdminOtherUser(
                            role: AppConstants.branch,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildSectionTitle(context, LocaleKeys.change_language.tr()),
                  const SizedBox(height: 6),
                  const LanguageButton(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, LocaleKeys.app_version.tr()),
                  const SizedBox(height: 8),
                  _buildVersionTile(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionTile() {
    final updateService = AppUpdateService();
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.lightBlueAccent,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${LocaleKeys.version.tr()} ${updateService.currentVersion}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Haus des Döner Control App',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
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
        backgroundColor: const Color(0xFF212121),
        title: Text(
          LocaleKeys.logout.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          LocaleKeys.confirmLogoutMessage.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: const TextStyle(color: Colors.white70),
            ),
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

      // Only navigate back if logout was successful and context is still mounted
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error if logout fails
      if (context.mounted) {
        showSnakBarr(context, '$e');
      }
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.settings, color: Colors.lightBlueAccent),
        const SizedBox(width: 6),
        Text(
          LocaleKeys.adminSettings.tr(),
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

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.blueGrey,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
