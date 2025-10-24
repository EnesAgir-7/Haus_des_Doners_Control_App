import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_firebase_services/admin_template_service.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/branch_model.dart';
import '../admin_providers/provider_admin_branches.dart';
import '../widgets/admin_location_picker.dart';
import '../widgets/admin_template_selection_sheet.dart';

class ScreenAdminAddBranch extends StatefulWidget {
  const ScreenAdminAddBranch({super.key});

  @override
  State<ScreenAdminAddBranch> createState() => _ScreenAdminAddBranchState();
}

class _ScreenAdminAddBranchState extends State<ScreenAdminAddBranch> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _regionController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String? _selectedTemplateId;
  String? _selectedTemplateName;
  String? _selectedInspectorId;
  String? _selectedInspectorName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: 'Add New Branch'),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Branch Information', Icons.store),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Branch Name',
                      hint: 'Enter branch name',
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Branch name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter branch address',
                      icon: Icons.location_on,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _regionController,
                      label: 'Region (Optional)',
                      hint: 'Enter region',
                      icon: Icons.map,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Contact Information',
                      Icons.contact_phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _contactNameController,
                      label: 'Contact Name',
                      hint: 'Enter contact person name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Contact name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _contactPhoneController,
                      label: 'Contact Phone',
                      hint: 'Enter contact phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Contact phone is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Location (GPS)', Icons.gps_fixed),
                    const SizedBox(height: 16),
                    // Replace the latitude/longitude fields with this:
                    InkWell(
                      onTap: () async {
                        final result = await showLocationPickerDialog(
                          context,
                          initialLatitude: double.tryParse(
                            _latitudeController.text,
                          ),
                          initialLongitude: double.tryParse(
                            _longitudeController.text,
                          ),
                          googleMapsApiKey:
                              'YOUR_GOOGLE_MAPS_API_KEY', // Add your API key
                        );

                        if (result != null) {
                          setState(() {
                            _latitudeController.text = result['latitude']
                                .toStringAsFixed(6);
                            _longitudeController.text = result['longitude']
                                .toStringAsFixed(6);
                            // Optional: You can also use result['address'] if needed
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.map, color: AppColors.primaryRed),
                            SizedBox(width: 12),
                            Text(
                              _latitudeController.text.isEmpty
                                  ? 'Pick location from map'
                                  : '${_latitudeController.text}, ${_longitudeController.text}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Questionnaire.& Inspector',
                      Icons.assignment,
                    ),
                    const SizedBox(height: 16),
                    _buildTemplateSelector(),
                    const SizedBox(height: 16),
                    _buildInspectorSelector(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
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
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(icon, color: AppColors.primaryRed, size: 20),
            filled: true,
            fillColor: AppColors.primaryDark.withValues(alpha: 0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inspection Template',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showTemplateSelectionSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedTemplateName ?? 'Select inspection template',
                    style: TextStyle(
                      color: _selectedTemplateName != null
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (_selectedTemplateName == null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              'Template is required',
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInspectorSelector() {
    return Consumer<ProviderAdminUsers>(
      builder: (context, userProvider, _) {
        final inspectors = userProvider.inspectors;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assigned Inspector (Optional)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showInspectorSelectionSheet(inspectors),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedInspectorName ?? 'Select inspector (optional)',
                        style: TextStyle(
                          color: _selectedInspectorName != null
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_selectedInspectorName != null)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _selectedInspectorId = null;
                            _selectedInspectorName = null;
                          });
                        },
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Branch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryDark,
      builder: (context) {
        return TemplateSelectionSheet(
          templateHelper: TemplateHelper(),
          onTemplateSelected: (template) async {
            _selectedTemplateId = template.id;
            _selectedTemplateName = template.name;
            setState(() {});
          },
        );
      },
    );
  }

  void _showInspectorSelectionSheet(List<dynamic> inspectors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryDark,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Inspector',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: inspectors.isEmpty
                    ? Center(
                        child: Text(
                          'No inspectors available',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: inspectors.length,
                        itemBuilder: (context, index) {
                          final inspector = inspectors[index];
                          // Adjust these field names based on your inspector model
                          final inspectorId = inspector.id ?? inspector['id'];
                          final inspectorName =
                              inspector.name ?? inspector['name'] ?? 'Unknown';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryRed.withValues(
                                alpha: 0.2,
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            title: Text(
                              inspectorName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedInspectorId = inspectorId;
                                _selectedInspectorName = inspectorName;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an inspection template'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());

      final branch = BranchModel(
        id: '', // leave empty to generate automatically in Firestore
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        templateId: _selectedTemplateId!,
        templateName: _selectedTemplateName!,
        region: _regionController.text.trim().isEmpty
            ? null
            : _regionController.text.trim(),
        gps: GeoPoint(latitude, longitude),
        contactName: _contactNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        stop: null, // optional, assign if you have a stop
        assignedInspector: _selectedInspectorId != null
            ? AssignedInspector(
                id: _selectedInspectorId!,
                name: _selectedInspectorName!,
              )
            : null,
        lastInspectionDate: null,
        lastInspectionScore: null,
        totalInspections: 0,
        averageScore: 0.0,
        status: 'active',
        last12MonthsScores: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<ProviderAdminBranches>();
      // You'll need to implement this method in your provider
      final success = await provider.addBranch(branch: branch);

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Branch created successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create branch'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
