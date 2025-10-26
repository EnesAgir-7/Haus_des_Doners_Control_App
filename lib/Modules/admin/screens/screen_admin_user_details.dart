// =====================================================
// SCREEN 2: User Details/Edit Screen
// =====================================================

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/lib/translations/locale_keys.g.dart';
import '../../../models/user_model.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../../inspector/widgets/custom_toast.dart';
import '../admin_providers/provider_admin_users.dart';

class ScreenAdminUserDetails extends StatefulWidget {
  final UserModel user;

  const ScreenAdminUserDetails({super.key, required this.user});

  @override
  State<ScreenAdminUserDetails> createState() => _ScreenAdminUserDetailsState();
}

class _ScreenAdminUserDetailsState extends State<ScreenAdminUserDetails> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _regionController;
  late String _selectedRole;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.serviceAccount);
    _regionController = TextEditingController(text: widget.user.region ?? '');
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProviderAdminUsers>();

    // Check what changed
    final nameChanged = _nameController.text.trim() != widget.user.name;

    final regionChanged =
        _regionController.text.trim() != (widget.user.region ?? '');
    final roleChanged = _selectedRole != widget.user.role;

    if (!nameChanged && !regionChanged && !roleChanged) {
      showSnakBarr(context, 'No changes detected');
      setState(() => _isEditing = false);
      return;
    }

    try {
      await provider.updateUser(
        userId: widget.user.id,
        name: nameChanged ? _nameController.text.trim() : null,
        region: regionChanged ? _regionController.text.trim() : null,
        role: roleChanged ? _selectedRole : null,
      );

      if (!mounted) return;

      showSnakBarr(context, 'User updated successfully');
      setState(() => _isEditing = false);
      Navigator.pop(context, true); 
    } catch (e) {
      if (!mounted) return;
      showSnakBarr(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(
        title: widget.user.name,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initializeControllers();
                });
              },
            ),
        ],
      ),
      body: Consumer<ProviderAdminUsers>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(
                    'User Information',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: LocaleKeys.name.tr(),
                    icon: Icons.badge,
                    enabled: _isEditing,
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
                    enabled: false,
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
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 32),
                  _buildAccountStatus(),
                  const SizedBox(height: 40),
                  if (_isEditing) _buildSaveButton(provider),
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
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: enabled ? Colors.white : Colors.white70),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? AppColors.primaryRed : Colors.white54,
        ),
        filled: true,
        fillColor: enabled
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      dropdownColor: AppColors.lightBlack,
      style: TextStyle(color: _isEditing ? Colors.white : Colors.white70),
      decoration: InputDecoration(
        labelText: LocaleKeys.role.tr(),
        labelStyle: TextStyle(
          color: _isEditing
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          Icons.verified_user,
          color: _isEditing ? AppColors.primaryRed : Colors.white54,
        ),
        filled: true,
        fillColor: _isEditing
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
      onChanged: _isEditing
          ? (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            }
          : null,
    );
  }

  Widget _buildAccountStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            widget.user.active ? Icons.check_circle : Icons.cancel,
            color: widget.user.active ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Status',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.active ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: widget.user.active ? Colors.green : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ProviderAdminUsers provider) {
    return ElevatedButton(
      onPressed: provider.isLoading ? null : _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.5),
      ),
      child: provider.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.save, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }
}
