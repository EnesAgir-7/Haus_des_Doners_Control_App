import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/provider_admin_users.dart';
import '../../translations/locale_keys.g.dart';
import '../widgets/assign_branch_dialog.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final UserModel initialUser;
  final void Function(UserModel) onUserUpdated;

  const AdminUserDetailsScreen({
    super.key,
    required this.initialUser,
    required this.onUserUpdated,
  });

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  late UserModel user;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _regionController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    user = widget.initialUser;
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _regionController = TextEditingController(text: user.region ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers if cancelling edit
        _nameController.text = user.name;
        _emailController.text = user.email;
        _regionController.text = user.region ?? '';
      }
    });
  }

  Future<void> _saveChanges() async {
    final provider = context.read<ProviderAdminUsers>();
    try {
      final updatedUser = await provider.updateUser(user.id, {
        'name': _nameController.text,
        'email': _emailController.text,
        'region': _regionController.text.isEmpty
            ? null
            : _regionController.text,
      });
      if (mounted) {
        setState(() {
          user = updatedUser;
        });
        widget.onUserUpdated(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.user_updated_successfully.tr())),
        );
        _toggleEdit();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEdit,
          ),
          if (_isEditing)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryRed,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoField(
              label: LocaleKeys.name.tr(),
              controller: _nameController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildInfoField(
              label: LocaleKeys.email.tr(),
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildInfoField(
              label: LocaleKeys.region.tr(),
              controller: _regionController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              label: LocaleKeys.role.tr(),
              value: user.role.toUpperCase(),
              valueColor: user.isAdmin ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              label: LocaleKeys.status.tr(),
              value: user.active
                  ? LocaleKeys.active.tr()
                  : LocaleKeys.inactive.tr(),
              valueColor: user.active ? Colors.green : Colors.grey,
            ),
            if (user.isInspector) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.assigned_branches.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primaryRed,
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AssignBranchDialog(
                          user: user,
                          assignedBranches: context
                              .read<ProviderAdminUsers>()
                              .getUserBranches(user.id),
                        ),
                      );
                      if (result == true) {
                        // Refresh the branches list
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<ProviderAdminUsers>(
                builder: (context, provider, child) {
                  final assignedBranches = provider.getUserBranches(user.id);
                  if (assignedBranches.isEmpty) {
                    return Center(
                      child: Text(
                        LocaleKeys.no_branches_assigned.tr(),
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: assignedBranches.length,
                    itemBuilder: (context, index) {
                      final branch = assignedBranches[index];
                      return Card(
                        color: AppColors.lightBlack,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(branch.name),
                          subtitle: Text(branch.address),
                          trailing: Text(
                            branch.region ?? '',
                            style: TextStyle(color: AppColors.primaryRed),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    bool enabled = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: enabled ? Colors.white : Colors.white70),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryRed),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
