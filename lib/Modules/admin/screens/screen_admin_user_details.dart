import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/app_button.dart';
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
      showSnakBarr(context, LocaleKeys.noChangesDetected.tr());
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

      showSnakBarr(context, LocaleKeys.userUpdatedSuccess.tr());
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
        actions: widget.user.role == AppConstants.branch
            ? []
            : [
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
                    LocaleKeys.userInformation.tr(),
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
                    LocaleKeys.roleAndRegion.tr(),
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
                  if (!provider.isLoading) ...[
                    _buildAccountStatus(),
                    const SizedBox(height: 40),
                    if (_isEditing && widget.user.role != AppConstants.branch)
                      _buildSaveButton(provider),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Don't show update password for branch users
                        Expanded(child: _buildUpdatePasswordButton(provider)),
                        const SizedBox(width: 16),

                        Expanded(child: _buildDeleteAccountButton(provider)),
                      ],
                    ),
                  ] else ...[
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 16),
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
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
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
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: AppConstants.admin,
          child: Text(LocaleKeys.admin.tr()),
        ),
        DropdownMenuItem(
          value: AppConstants.inspector,
          child: Text(LocaleKeys.inspector.tr()),
        ),
        DropdownMenuItem(
          value: AppConstants.branch,
          child: Text(LocaleKeys.branch.tr()),
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
                  LocaleKeys.accountStatus.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.active
                      ? LocaleKeys.active.tr()
                      : LocaleKeys.inactive.tr(),
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
    return AppButton(
      onPressed: provider.isLoading ? null : _saveChanges,
      isLoading: provider.isLoading,
      text: LocaleKeys.saveChanges.tr(),
      backgroundColor: AppColors.primaryRed,
      icon: Icons.save,
    );
  }

  Widget _buildDeleteAccountButton(ProviderAdminUsers provider) {
    return AppButton(
      onPressed: () => _showDeleteAccountDialog(provider, widget.user, context),
      isLoading: provider.isLoading,
      text: LocaleKeys.deleteAccount.tr(),
      backgroundColor: AppColors.primaryRed,
      icon: Icons.delete,
    );
  }

  Widget _buildUpdatePasswordButton(ProviderAdminUsers provider) {
    return AppButton(
      onPressed: () => showUpdatePasswordDialog(
        context: context,
        inspectorUid: widget.user.id,
      ),
      backgroundColor: AppColors.green,
      isLoading: provider.isLoading,
      text: LocaleKeys.updatePassword.tr(),
      icon: Icons.delete,
    );
  }

  Future<void> showUpdatePasswordDialog({
    required BuildContext context,
    required String inspectorUid,
  }) async {
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocaleKeys.updateInspectorPassword.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: LocaleKeys.enterNewPassword.tr(),
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.primaryDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocaleKeys.pleaseEnterPassword.tr();
                  }
                  if (value.length < 6) {
                    return LocaleKeys.passwordMinLength.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: LocaleKeys.confirmPassword.tr(),
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.primaryDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return LocaleKeys.passwordsNotMatch.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(ctx); // close dialog immediately
                // Call Provider method
                final provider = context.read<ProviderAdminUsers>();
                await provider.updateInspectorPassword(
                  inspectorUid: inspectorUid,
                  newPassword: _passwordController.text.trim(),
                  parentContext: context,
                );
              }
            },
            child: Text(
              LocaleKeys.update.tr(),
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(
    ProviderAdminUsers provider,
    UserModel user,
    BuildContext parentContext,
  ) async {
    // Check user type and show appropriate dialog
    if (user.role == AppConstants.inspector) {
      return _showDeleteInspectorDialog(provider, user, parentContext);
    } else {
      return _showDeleteUserDialog(provider, user, parentContext);
    }
  }

  // Dialog for deleting Inspector (with detailed warnings)
  Future<void> _showDeleteInspectorDialog(
    ProviderAdminUsers provider,
    UserModel inspectorUser,
    BuildContext parentContext,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.lightBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  LocaleKeys.deleteInspectorAccount.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.deleteInspectorConfirm.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      LocaleKeys.inspector.tr(),
                      inspectorUser.name,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      LocaleKeys.email.tr(),
                      inspectorUser.serviceAccount,
                    ),
                    if (inspectorUser.region != null &&
                        inspectorUser.region!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        LocaleKeys.region.tr(),
                        inspectorUser.region!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          LocaleKeys.deleteActionIrreversible.tr(),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      LocaleKeys.inspectorAuthAccount.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocaleKeys.inspectorUserData.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocaleKeys.inspectorRouteIfEmpty.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocaleKeys.cancel.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // close confirmation dialog

                await provider.deleteInspector(
                  inspectorUid: inspectorUser.id,
                  parentContext: parentContext,
                );
              },
              child: Text(LocaleKeys.delete.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteUserDialog(
    ProviderAdminUsers provider,
    UserModel user,
    BuildContext parentContext,
  ) async {
    final String userTypeLabel = user.role == AppConstants.admin
        ? LocaleKeys.admin.tr()
        : LocaleKeys.branch.tr();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.lightBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${LocaleKeys.delete.tr()} $userTypeLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${LocaleKeys.deleteInspectorConfirm.tr().replaceAll("inspector", userTypeLabel)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(LocaleKeys.name.tr(), user.name),
                    const SizedBox(height: 8),
                    _buildInfoRow(LocaleKeys.email.tr(), user.serviceAccount),
                    const SizedBox(height: 8),
                    _buildInfoRow(LocaleKeys.role.tr(), userTypeLabel),
                    if (user.region != null && user.region!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(LocaleKeys.region.tr(), user.region!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LocaleKeys.deleteActionIrreversible.tr(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocaleKeys.cancel.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // close confirmation dialog

                await provider.deleteUser(
                  userUid: user.id,
                  parentContext: parentContext,
                );
              },
              child: Text(LocaleKeys.delete.tr()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
