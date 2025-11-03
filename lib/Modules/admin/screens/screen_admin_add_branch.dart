import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:haus_des_control/Modules/admin/admin_firebase_services/admin_template_service.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:provider/provider.dart';

import '../../../common_services/user_selection_sheet.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/branch_model.dart';
import '../../../translations/locale_keys.g.dart';
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
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // New controllers
  final _branchEmailController = TextEditingController();
  final _openingTimeController = TextEditingController();
  final _closingTimeController = TextEditingController();
  final _donerPricesController = TextEditingController();
  final _softwareController = TextEditingController();
  final _shopInformationController = TextEditingController();

  String? _selectedTemplateId;
  String? _selectedTemplateName;
  String? _selectedInspectorId;
  String? _selectedInspectorName;
  bool _isSubmitting = false;

  // New fields
  List<String> _selectedOpeningDays = [];
  DateTime? _selectedOpeningDay;
  List<ContactPerson> _branchOwners = [];
  List<ContactPerson> _branchManagers = [];
  List<ContactPerson> _suppliers = [];

  final List<String> _daysOfWeek = [
    LocaleKeys.monday.tr(),
    LocaleKeys.tuesday.tr(),
    LocaleKeys.wednesday.tr(),
    LocaleKeys.thursday.tr(),
    LocaleKeys.friday.tr(),
    LocaleKeys.saturday.tr(),
    LocaleKeys.sunday.tr(),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _branchEmailController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _donerPricesController.dispose();
    _softwareController.dispose();
    _shopInformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: LocaleKeys.addNewBranch.tr()),
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
                    _buildSectionHeader(
                      LocaleKeys.branchInformation.tr(),
                      Icons.store,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: LocaleKeys.branchName.tr(),
                      hint: LocaleKeys.enterBranchName.tr(),
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return LocaleKeys.branchNameRequired.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _branchEmailController,
                      label: LocaleKeys.branchEmail.tr(),
                      hint: LocaleKeys.enterBranchEmail.tr(),
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return LocaleKeys.branchEmailRequired.tr();
                        }
                        if (!value.contains('@')) {
                          return LocaleKeys.enterValidEmail.tr();
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      LocaleKeys.location.tr(),
                      Icons.location_on,
                    ),
                    const SizedBox(height: 16),
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
                          googleMapsApiKey: dotenv.env['GOOGLE_MAPS_KEY']!,
                        );

                        if (result != null) {
                          setState(() {
                            _latitudeController.text = result['latitude']
                                .toString();
                            _longitudeController.text = result['longitude']
                                .toString();
                            _addressController.text = result['address']
                                .toString();
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
                            Expanded(
                              child: Text(
                                _latitudeController.text.isEmpty
                                    ? LocaleKeys.pickLocationFromMap.tr()
                                    : '${_latitudeController.text}, ${_longitudeController.text}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: LocaleKeys.address.tr(),
                      hint: LocaleKeys.enterBranchAddress.tr(),
                      icon: Icons.location_on,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return LocaleKeys.addressRequired.tr();
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      LocaleKeys.contactInformation.tr(),
                      Icons.contact_phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _contactNameController,
                      label: LocaleKeys.contactName.tr(),
                      hint: LocaleKeys.enterContactPersonName.tr(),
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return LocaleKeys.contactNameRequired.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _contactPhoneController,
                      label: LocaleKeys.contactPhone.tr(),
                      hint: LocaleKeys.enterContactPhoneNumber.tr(),
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return LocaleKeys.contactPhoneRequired.tr();
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      LocaleKeys.openingHoursDays.tr(),
                      Icons.schedule,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeField(
                            controller: _openingTimeController,
                            label: LocaleKeys.openingTime.tr(),
                            hint: 'HH:MM',
                            icon: Icons.access_time,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeField(
                            controller: _closingTimeController,
                            label: LocaleKeys.closingTime.tr(),
                            hint: 'HH:MM',
                            icon: Icons.access_time_filled,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildOpeningDaysSelector(),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: LocaleKeys.openingDay.tr(),
                      hint: LocaleKeys.selectOpeningDay.tr(),
                      icon: Icons.calendar_today,
                      selectedDate: _selectedOpeningDay,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedOpeningDay ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _selectedOpeningDay = date);
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      LocaleKeys.branchOwners.tr(),
                      Icons.business_center,
                    ),
                    const SizedBox(height: 16),
                    _buildContactPersonList(
                      persons: _branchOwners,
                      onAdd: () => _showAddContactPersonDialog(
                        title: LocaleKeys.addBranchOwner.tr(),
                        onSave: (person) {
                          setState(() => _branchOwners.add(person));
                        },
                      ),
                      onRemove: (index) {
                        setState(() => _branchOwners.removeAt(index));
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      LocaleKeys.branchManagers.tr(),
                      Icons.manage_accounts,
                    ),
                    const SizedBox(height: 16),
                    _buildContactPersonList(
                      persons: _branchManagers,
                      onAdd: () => _showAddContactPersonDialog(
                        title: LocaleKeys.addBranchManager.tr(),
                        onSave: (person) {
                          setState(() => _branchManagers.add(person));
                        },
                      ),
                      onRemove: (index) {
                        setState(() => _branchManagers.removeAt(index));
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      LocaleKeys.suppliers.tr(),
                      Icons.local_shipping,
                    ),
                    const SizedBox(height: 16),
                    _buildContactPersonList(
                      persons: _suppliers,
                      onAdd: () => _showAddContactPersonDialog(
                        showRole: true,
                        title: LocaleKeys.addSupplier.tr(),
                        onSave: (person) {
                          setState(() => _suppliers.add(person));
                        },
                      ),
                      onRemove: (index) {
                        setState(() => _suppliers.removeAt(index));
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      LocaleKeys.shopInformation.tr(),
                      Icons.info,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _donerPricesController,
                      label: LocaleKeys.donerPrices.tr(),
                      hint: LocaleKeys.enterDonerPrices.tr(),
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _softwareController,
                      label: LocaleKeys.software.tr(),
                      hint: LocaleKeys.enterSoftwareUsed.tr(),
                      icon: Icons.computer,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _shopInformationController,
                      label: LocaleKeys.additionalInformation.tr(),
                      hint: LocaleKeys.enterShopInformation.tr(),
                      icon: Icons.description,
                      maxLines: 5,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      LocaleKeys.questionnaireInspector.tr(),
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

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              controller.text = time.format(context);
              setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 12),
                Text(
                  controller.text.isEmpty ? hint : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required IconData icon,
    required DateTime? selectedDate,
    required VoidCallback onTap,
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
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 12),
                Text(
                  selectedDate == null
                      ? hint
                      : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: TextStyle(
                    color: selectedDate == null
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpeningDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.openingDays.tr(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showOpeningDaysSheet,
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
                Icon(
                  Icons.calendar_month,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedOpeningDays.isEmpty
                        ? LocaleKeys.selectOpeningDays.tr()
                        : _selectedOpeningDays.join(', '),
                    style: TextStyle(
                      color: _selectedOpeningDays.isEmpty
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white,
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
      ],
    );
  }

  Widget _buildContactPersonList({
    required List<ContactPerson> persons,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    if (persons.isEmpty) {
      // 🔹 No contact persons → show full-width “Add” card
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryRed.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primaryRed,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.pleaseClickToAddContact.tr(),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 🔹 When persons are available → show scrollable list with small “+” button
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...persons.asMap().entries.map((entry) {
                final person = entry.value;
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryRed.withValues(
                          alpha: 0.2,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Colors.white60,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    person.phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => onRemove(entry.key),
                      ),
                    ],
                  ),
                );
              }),

              // 🔹 Small “Add” card at the end
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryRed.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      color: AppColors.primaryRed,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
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
          LocaleKeys.inspectionTemplate.tr(),
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
                    _selectedTemplateName ??
                        LocaleKeys.selectInspectionTemplate.tr(),
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
              LocaleKeys.templateRequired.tr(),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.assignedInspector.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final inspector = await showInspectorPicker(context: context);

                if (inspector != null) {
                  setState(() {
                    _selectedInspectorId = inspector.id;
                    _selectedInspectorName = inspector.name;
                  });
                }
              },
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
                        _selectedInspectorName ??
                            LocaleKeys.selectInspectorOptional.tr(),
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
                child: Text(
                  LocaleKeys.cancel.tr(),
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
                    : Text(
                        LocaleKeys.createBranch.tr(),

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
          showNote: false,
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

  void _showOpeningDaysSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryDark,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocaleKeys.selectOpeningDaysTitle.tr(),
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
                    child: ListView.builder(
                      itemCount: _daysOfWeek.length,
                      itemBuilder: (context, index) {
                        final day = _daysOfWeek[index];
                        final isSelected = _selectedOpeningDays.contains(day);

                        return CheckboxListTile(
                          title: Text(
                            day,
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: isSelected,
                          activeColor: AppColors.primaryRed,
                          checkColor: Colors.white,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                _selectedOpeningDays.add(day);
                              } else {
                                _selectedOpeningDays.remove(day);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(LocaleKeys.done.tr()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddContactPersonDialog({
    required String title,
    bool showRole = false,
    required Function(ContactPerson) onSave,
  }) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryDark,
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: LocaleKeys.name.tr(),
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: LocaleKeys.phone.tr(),
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (showRole)
                TextField(
                  controller: roleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: LocaleKeys.role.tr(),
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryRed),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.cancel.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty &&
                    (!showRole || roleController.text.isNotEmpty)) {
                  onSave(
                    ContactPerson(
                      name: nameController.text,
                      phone: phoneController.text,
                      role: roleController.text,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
              ),
              child: Text(LocaleKeys.save.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTemplateId == null) {
      showSnakBarr(context, LocaleKeys.pleaseSelectTemplate.tr());
      return;
    }

    if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
      showSnakBarr(context, LocaleKeys.pleaseSelectLocation.tr());

      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());

      final branch = BranchModel(
        id: '',
        name: _nameController.text.trim(),
        region: "",
        address: _addressController.text.trim(),
        templateId: _selectedTemplateId!,
        templateName: _selectedTemplateName!,
        gps: GeoPoint(latitude, longitude),
        contactName: _contactNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        stop: null,
        assignedInspector: _selectedInspectorId != null
            ? AssignedInspector(
                id: _selectedInspectorId!,
                name: _selectedInspectorName!,
              )
            : null,
        lastInspectionDate: null,
        lastInspectionScore: null,
        totalInspections: 0,
        averageScore: "0/0",
        status: AppConstants.active,
        last12MonthsScores: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // New fields
        branchEmail: _branchEmailController.text.trim().isNotEmpty
            ? _branchEmailController.text.trim()
            : null,
        openingHours:
            _openingTimeController.text.isNotEmpty &&
                _closingTimeController.text.isNotEmpty
            ? OpeningHours(
                openingTime: _openingTimeController.text,
                closingTime: _closingTimeController.text,
              )
            : null,
        openingDays: _selectedOpeningDays.isNotEmpty
            ? _selectedOpeningDays
            : null,
        openingDay: _selectedOpeningDay,
        suppliers: _suppliers.isNotEmpty ? _suppliers : null,
        donerPrices: _donerPricesController.text.trim().isNotEmpty
            ? _donerPricesController.text.trim()
            : null,
        software: _softwareController.text.trim().isNotEmpty
            ? _softwareController.text.trim()
            : null,
        shopInformation: _shopInformationController.text.trim().isNotEmpty
            ? _shopInformationController.text.trim()
            : null,
        branchOwners: _branchOwners.isNotEmpty ? _branchOwners : null,
        branchManagers: _branchManagers.isNotEmpty ? _branchManagers : null,
      );

      final provider = context.read<ProviderAdminBranches>();
      final success = await provider.addBranch(branch: branch);

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (success) {
          showSnakBarr(context, LocaleKeys.branchCreatedSuccess.tr());
          Navigator.of(context).pop();
        } else {
          showSnakBarr(context, LocaleKeys.failedToCreateBranch.tr());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
