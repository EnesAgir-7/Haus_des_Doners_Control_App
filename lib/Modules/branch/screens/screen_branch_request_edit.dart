import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:provider/provider.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/Modules/admin/widgets/admin_location_picker.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/branch_model.dart';
import '../branch_providers/provider_branch_update_request.dart';

class ScreenBranchRequestEdit extends StatefulWidget {
  final BranchModel branch;
  const ScreenBranchRequestEdit({super.key, required this.branch});

  @override
  State<ScreenBranchRequestEdit> createState() =>
      _ScreenBranchRequestEditState();
}

class _ScreenBranchRequestEditState extends State<ScreenBranchRequestEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _branchEmailController;
  late TextEditingController _openingTimeController;
  late TextEditingController _closingTimeController;
  late TextEditingController _donerPricesController;
  late TextEditingController _softwareController;
  late TextEditingController _shopInformationController;

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
  void initState() {
    super.initState();
    _initializeControllers();
    _checkPendingRequest();
  }

  void _initializeControllers() {
    final b = widget.branch;
    _nameController = TextEditingController(text: b.name);
    _addressController = TextEditingController(text: b.address);
    _contactNameController = TextEditingController(text: b.contactName);
    _contactPhoneController = TextEditingController(text: b.contactPhone);
    _latitudeController = TextEditingController(
      text: b.gps.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: b.gps.longitude.toString(),
    );
    _branchEmailController = TextEditingController(text: b.branchEmail ?? '');
    _openingTimeController = TextEditingController(
      text: b.openingHours?.openingTime ?? '',
    );
    _closingTimeController = TextEditingController(
      text: b.openingHours?.closingTime ?? '',
    );
    _donerPricesController = TextEditingController(text: b.donerPrices ?? '');
    _softwareController = TextEditingController(text: b.software ?? '');
    _shopInformationController = TextEditingController(
      text: b.shopInformation ?? '',
    );

    _selectedOpeningDays = List.from(b.openingDays ?? []);
    _selectedOpeningDay = b.openingDay;
    _branchOwners = List.from(b.branchOwners ?? []);
    _branchManagers = List.from(b.branchManagers ?? []);
    _suppliers = List.from(b.suppliers ?? []);
  }

  void _checkPendingRequest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchUpdateRequestProvider>().checkPendingRequest(
        widget.branch.id,
      );
    });
  }

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

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = loggedInUser?.id ?? '';
    final userName = loggedInUser?.name ?? '';

    if (userId.isEmpty) {
      showSnakBarr(context, LocaleKeys.user_not_authenticated.tr());
      return;
    }

    // Create updated branch with new values
    final updatedBranch = widget.branch.copyWith(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      branchEmail: _branchEmailController.text.trim(),
      gps:
          (double.tryParse(_latitudeController.text.trim()) != null &&
              double.tryParse(_longitudeController.text.trim()) != null)
          ? GeoPoint(
              double.parse(_latitudeController.text.trim()),
              double.parse(_longitudeController.text.trim()),
            )
          : widget.branch.gps,
      openingHours: OpeningHours(
        openingTime: _openingTimeController.text.trim(),
        closingTime: _closingTimeController.text.trim(),
      ),
      openingDays: _selectedOpeningDays,
      openingDay: _selectedOpeningDay,
      donerPrices: _donerPricesController.text.trim(),
      software: _softwareController.text.trim(),
      shopInformation: _shopInformationController.text.trim(),
      branchOwners: _branchOwners,
      branchManagers: _branchManagers,
      suppliers: _suppliers,
      updatedAt: DateTime.now(),
    );

    // Submit via provider
    final provider = context.read<BranchUpdateRequestProvider>();
    final success = await provider.submitUpdateRequest(
      oldBranch: widget.branch,
      newBranch: updatedBranch,
      requestedBy: userId,
      requestedByName: userName,
      context: context,
    );

    if (success && mounted) {
      Navigator.pop(context, true); // Return true to indicate success
    }
  }

  void _pickLocation() async {
    final result = await showLocationPickerDialog(
      context,
      initialLatitude: double.tryParse(_latitudeController.text),
      initialLongitude: double.tryParse(_longitudeController.text),
      googleMapsApiKey: dotenv.env['GOOGLE_MAPS_KEY'] ?? '',
    );

    if (result != null) {
      setState(() {
        _latitudeController.text = result['latitude'].toString();
        _longitudeController.text = result['longitude'].toString();
        _addressController.text = result['address'].toString();
      });
    }
  }

  Future<void> _showAddContactPersonDialog({
    required String title,
    required Function(ContactPerson) onSave,
  }) async {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final roleC = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: LocaleKeys.name.tr(),
                labelStyle: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: phoneC,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: LocaleKeys.phone.tr(),
                labelStyle: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: roleC,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: LocaleKeys.role_optional.tr(),
                labelStyle: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: Text(LocaleKeys.save.tr()),
          ),
        ],
      ),
    );

    if (ok == true) {
      final cp = ContactPerson(
        name: nameC.text.trim(),
        phone: phoneC.text.trim(),
        role: roleC.text.trim(),
      );
      onSave(cp);
      setState(() {});
    }
  }

  Future<void> _showEditContactPersonDialog({
    required String title,
    required ContactPerson initial,
    required Function(ContactPerson) onSave,
  }) async {
    final nameC = TextEditingController(text: initial.name);
    final phoneC = TextEditingController(text: initial.phone);
    final roleC = TextEditingController(text: initial.role ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: LocaleKeys.name.tr(),
                labelStyle: const TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: phoneC,
              style: const TextStyle(color: Colors.white),

              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: LocaleKeys.phone.tr(),
                labelStyle: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: roleC,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: LocaleKeys.role_optional.tr(),
                labelStyle: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: Text(LocaleKeys.save.tr()),
          ),
        ],
      ),
    );

    if (ok == true) {
      final cp = ContactPerson(
        name: nameC.text.trim(),
        phone: phoneC.text.trim(),
        role: roleC.text.trim(),
      );
      onSave(cp);
      setState(() {});
    }
  }

  Widget _buildPendingRequestBanner() {
    return Consumer<BranchUpdateRequestProvider>(
      builder: (context, provider, child) {
        if (!provider.hasPendingRequest) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange),
          ),
          child: Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.orange, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Update Request',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.pendingChangesCount} changes waiting for approval',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showDeleteRequestConfirmation(provider),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete Request',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteRequestConfirmation(BranchUpdateRequestProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text(
          'Delete Request',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete your pending update request?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deletePendingRequest(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryRed),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: AppColors.primaryDark.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InkWell(
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
      child: IgnorePointer(
        child: _buildTextField(
          controller: controller,
          label: label,
          hint: hint,
          icon: icon,
        ),
      ),
    );
  }

  Widget _buildOpeningDaysSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _daysOfWeek.map((d) {
        final selected = _selectedOpeningDays.contains(d);
        return FilterChip(
          label: Text(d),
          selected: selected,
          selectedColor: AppColors.white,
          onSelected: (v) {
            setState(() {
              if (v) {
                _selectedOpeningDays.add(d);
              } else {
                _selectedOpeningDays.remove(d);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildContactPersonList({
    required String title,
    required List<ContactPerson> persons,
    required VoidCallback onAdd,
    required Function(int, ContactPerson) onEdit,
    required Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: AppColors.primaryRed),
              label: Text(
                LocaleKeys.add.tr(),
                style: const TextStyle(color: AppColors.primaryRed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...persons.asMap().entries.map((e) {
          final idx = e.key;
          final p = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        p.phone,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      if (p.role != null && p.role!.isNotEmpty)
                        Text(
                          p.role!,
                          style: TextStyle(
                            color: AppColors.primaryRed.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditContactPersonDialog(
                    title: LocaleKeys.edit.tr(),
                    initial: p,
                    onSave: (newP) => onEdit(idx, newP),
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white70),
                ),
                IconButton(
                  onPressed: () => onRemove(idx),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: LocaleKeys.update_request.tr()),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Pending request banner
            _buildPendingRequestBanner(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branch Information
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
                    // Location
                    _buildSectionHeader(
                      LocaleKeys.location.tr(),
                      Icons.location_on,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickLocation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map, color: AppColors.primaryRed),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_latitudeController.text}, ${_longitudeController.text}',
                                style: const TextStyle(color: Colors.white),
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
                    // Contact Information
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
                    // Opening Hours
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            LocaleKeys.openingDay.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  _selectedOpeningDay ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => _selectedOpeningDay = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedOpeningDay != null
                                      ? DateFormat.yMMMd().format(
                                          _selectedOpeningDay!,
                                        )
                                      : LocaleKeys.selectOpeningDay.tr(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Branch Owners
                    _buildSectionHeader(
                      LocaleKeys.branchOwners.tr(),
                      Icons.business_center,
                    ),
                    const SizedBox(height: 16),
                    _buildContactPersonList(
                      title: '',
                      persons: _branchOwners,
                      onAdd: () => _showAddContactPersonDialog(
                        title: LocaleKeys.addBranchOwner.tr(),
                        onSave: (person) =>
                            setState(() => _branchOwners.add(person)),
                      ),
                      onEdit: (index, person) =>
                          setState(() => _branchOwners[index] = person),
                      onRemove: (index) =>
                          setState(() => _branchOwners.removeAt(index)),
                    ),

                    const SizedBox(height: 24),
                    // Branch Managers
                    _buildSectionHeader(
                      LocaleKeys.branchManagers.tr(),
                      Icons.manage_accounts,
                    ),
                    const SizedBox(height: 16),
                    _buildContactPersonList(
                      title: '',
                      persons: _branchManagers,
                      onAdd: () => _showAddContactPersonDialog(
                        title: LocaleKeys.addBranchManager.tr(),
                        onSave: (person) =>
                            setState(() => _branchManagers.add(person)),
                      ),
                      onEdit: (index, person) =>
                          setState(() => _branchManagers[index] = person),
                      onRemove: (index) =>
                          setState(() => _branchManagers.removeAt(index)),
                    ),

                    const SizedBox(height: 24),
                    // Suppliers
                    _buildSectionHeader(
                      LocaleKeys.suppliers.tr(),
                      Icons.local_shipping,
                    ),
                    const SizedBox(height: 16),
                    _buildContactPersonList(
                      title: '',
                      persons: _suppliers,
                      onAdd: () => _showAddContactPersonDialog(
                        title: LocaleKeys.addSupplier.tr(),
                        onSave: (person) =>
                            setState(() => _suppliers.add(person)),
                      ),
                      onEdit: (index, person) =>
                          setState(() => _suppliers[index] = person),
                      onRemove: (index) =>
                          setState(() => _suppliers.removeAt(index)),
                    ),

                    const SizedBox(height: 24),
                    // Additional Information
                    _buildSectionHeader(
                      LocaleKeys.additionalInformation.tr(),
                      Icons.info_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _donerPricesController,
                      label: LocaleKeys.donerPrices.tr(),
                      hint: LocaleKeys.enterDonerPrices.tr(),
                      icon: Icons.price_change,
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
                      label: LocaleKeys.shopInformation.tr(),
                      hint: LocaleKeys.enterShopInformation.tr(),
                      icon: Icons.info,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),
                    // Submit Button
                    Consumer<BranchUpdateRequestProvider>(
                      builder: (context, provider, child) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: provider.isSubmitting
                                ? null
                                : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: provider.isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    LocaleKeys.update_request.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
