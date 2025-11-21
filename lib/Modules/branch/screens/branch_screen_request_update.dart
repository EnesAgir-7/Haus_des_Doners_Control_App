import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../branch_providers/provider_update_request.dart';

class ScreenUpdateRequest extends StatefulWidget {
  const ScreenUpdateRequest({super.key});

  @override
  State<ScreenUpdateRequest> createState() => _ScreenUpdateRequestState();
}

class _ScreenUpdateRequestState extends State<ScreenUpdateRequest> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProviderUpdateRequest>();
      provider.initialize();

      // Pre-fill with current branch info
      if (provider.branchInfo != null) {
        _nameController.text = provider.branchInfo!.name;
        _addressController.text = provider.branchInfo!.address;
        // _cityController.text = provider.branchInfo!.city;
        // _phoneController.text = provider.branchInfo!.phone;
        // _emailController.text = provider.branchInfo!.email;
        // _managerNameController.text = provider.branchInfo!.managerName;
        // _managerPhoneController.text = provider.branchInfo!.managerPhone;
        // _descriptionController.text = provider.branchInfo!.description ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _managerNameController.dispose();
    _managerPhoneController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProviderUpdateRequest>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.request_information_update.tr()),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
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
            stops: const [0.0, 0.25, 1.0],
          ),
        ),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      LocaleKeys.update_request_info.tr(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: LocaleKeys.branch_details.tr(),
                        icon: Icons.store,
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: LocaleKeys.branch_name.tr(),
                            icon: Icons.business,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _addressController,
                            label: LocaleKeys.address.tr(),
                            icon: Icons.location_on,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _cityController,
                            label: LocaleKeys.city.tr(),
                            icon: Icons.location_city,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: LocaleKeys.description.tr(),
                            icon: Icons.description,
                            maxLines: 3,
                            required: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: LocaleKeys.contact_information.tr(),
                        icon: Icons.contact_phone,
                        children: [
                          _buildTextField(
                            controller: _phoneController,
                            label: LocaleKeys.phone.tr(),
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: LocaleKeys.email.tr(),
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: LocaleKeys.manager_information.tr(),
                        icon: Icons.person,
                        children: [
                          _buildTextField(
                            controller: _managerNameController,
                            label: LocaleKeys.manager_name.tr(),
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _managerPhoneController,
                            label: LocaleKeys.manager_phone.tr(),
                            icon: Icons.phone_android,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: LocaleKeys.additional_notes.tr(),
                        icon: Icons.note,
                        children: [
                          _buildTextField(
                            controller: _notesController,
                            label: LocaleKeys.notes.tr(),
                            icon: Icons.note_outlined,
                            maxLines: 4,
                            required: false,
                            hint: LocaleKeys.add_notes_for_admin.tr(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.isSubmitting
                              ? null
                              : () => _submitRequest(provider),
                          icon: provider.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            provider.isSubmitting
                                ? LocaleKeys.submitting.tr()
                                : LocaleKeys.submit_request.tr(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryRed),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryRed),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return '${LocaleKeys.please_enter.tr()} $label';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _submitRequest(ProviderUpdateRequest provider) async {
    if (!_formKey.currentState!.validate()) return;

    final requestedChanges = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'managerName': _managerNameController.text.trim(),
      'managerPhone': _managerPhoneController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    final success = await provider.submitUpdateRequest(
      requestedChanges: requestedChanges,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.request_submitted_successfully.tr()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? LocaleKeys.error_submitting_request.tr(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
