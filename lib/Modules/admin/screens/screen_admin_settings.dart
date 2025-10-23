// lib/screens/admin/screen_admin_settings.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'screen_admin_templates.dart'; // Import the screen we just completed

class ScreenAdminSettings extends StatelessWidget {
  const ScreenAdminSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryRed.withValues(alpha: 0.08),
              AppColors.primaryDark,
              AppColors.primaryDark,
            ],
            stops: const [0.0, 0.15, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(context, 'Inspection Management'),
              _buildSettingsTile(
                context,
                icon: Icons.description,
                title: 'Inspection Templates',
                subtitle: 'Create, modify, and delete inspection forms.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScreenAdminTemplates(),
                    ),
                  );
                },
                color: AppColors.primaryRed,
              ),
              _buildSettingsTile(
                context,
                icon: Icons.category,
                title: 'Manage Categories (Dummy)',
                subtitle: 'Configure global inspection categories.',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'User & Access'),
              _buildSettingsTile(
                context,
                icon: Icons.people,
                title: 'Manage Users (Dummy)',
                subtitle: 'Add, edit, or remove admin and inspector accounts.',
                onTap: () {},
              ),
              _buildSettingsTile(
                context,
                icon: Icons.security,
                title: 'Security Settings (Dummy)',
                subtitle: 'Update passwords and security policies.',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'System'),
              _buildSettingsTile(
                context,
                icon: Icons.cloud_upload,
                title: 'Backup & Restore (Dummy)',
                subtitle: 'Manage cloud backup and data recovery.',
                onTap: () {},
              ),
              _buildSettingsTile(
                context,
                icon: Icons.info_outline,
                title: 'About App (Dummy)',
                subtitle: 'View version, licenses, and documentation.',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
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
          color: AppColors.lightBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
