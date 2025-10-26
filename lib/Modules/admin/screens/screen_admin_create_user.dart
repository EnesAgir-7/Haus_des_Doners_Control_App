import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/Modules/inspector/widgets/app_button.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../admin_providers/provider_admin_users.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_toast.dart';

class ScreenAdminCreateUser extends StatefulWidget {
  const ScreenAdminCreateUser({super.key});

  @override
  State<ScreenAdminCreateUser> createState() => _ScreenAdminCreateUserState();
}

class _ScreenAdminCreateUserState extends State<ScreenAdminCreateUser> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _reenterPasswordController = TextEditingController();
  final _regionController = TextEditingController();

  String _selectedRole = 'inspector';
  bool _showPassword = false;
  bool _showReenterPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _reenterPasswordController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProviderAdminUsers>();

    try {
      await provider.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        region: _regionController.text.trim().isEmpty
            ? null
            : _regionController.text.trim(),
      );

      if (!mounted) return;

      showSnakBarr(context, LocaleKeys.user_created_successfully.tr());
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      showSnakBarr(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: LocaleKeys.create_user.tr()),
      body: Consumer<ProviderAdminUsers>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('User Information', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: LocaleKeys.name.tr(),
                    icon: Icons.badge,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocaleKeys.name_required.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: LocaleKeys.email.tr(),
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocaleKeys.email_required.tr();
                      }
                      if (!value.contains('@')) {
                        return LocaleKeys.email_invalid.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Security', Icons.lock_outline),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: LocaleKeys.password.tr(),
                    icon: Icons.key,
                    obscureText: !_showPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.primaryRed,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocaleKeys.password_required.tr();
                      }
                      if (value.length < 6) {
                        return LocaleKeys.password_min_length.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _reenterPasswordController,
                    label: LocaleKeys.reenter_password.tr(),
                    icon: Icons.lock_reset,
                    obscureText: !_showReenterPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showReenterPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.primaryRed,
                      ),
                      onPressed: () {
                        setState(
                          () => _showReenterPassword = !_showReenterPassword,
                        );
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocaleKeys.password_required.tr();
                      }
                      if (value != _passwordController.text) {
                        return LocaleKeys.passwords_not_match.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    'Role & Region',
                    Icons.admin_panel_settings,
                  ),
                  const SizedBox(height: 16),
                  _buildRoleDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _regionController,
                    label: LocaleKeys.region.tr(),
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 40),
                  _buildCreateButton(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: AppColors.primaryRed),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      dropdownColor: AppColors.lightBlack,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: LocaleKeys.role.tr(),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(Icons.verified_user, color: AppColors.primaryRed),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
        ),
      ),
      items: [
        DropdownMenuItem(value: 'admin', child: Text(LocaleKeys.admin.tr())),
        DropdownMenuItem(
          value: 'inspector',
          child: Text(LocaleKeys.inspector.tr()),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedRole = value);
        }
      },
    );
  }

  Widget _buildCreateButton(ProviderAdminUsers provider) {
    return AppButton(
      isLoading: provider.isLoading,
      onPressed: provider.isLoading ? null : _createUser,
      icon: Icons.person_add,
      text: LocaleKeys.create_user.tr(),
    );
  }
}
