import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/app_button.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:haus_des_control/core/console.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../admin_providers/provider_admin_fleet.dart';
import '../admin_providers/provider_admin_users.dart';

class ScreenAdminVehicleDetails extends StatefulWidget {
  final VehicleModel vehicle;
  const ScreenAdminVehicleDetails({super.key, required this.vehicle});

  @override
  State<ScreenAdminVehicleDetails> createState() =>
      _ScreenAdminVehicleDetailsState();
}

class _ScreenAdminVehicleDetailsState extends State<ScreenAdminVehicleDetails> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _maxController = TextEditingController();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  String? _selectedInspectorId;
  String? _selectedInspectorName;
  DateTime? _lastServiceDate;
  DateTime? _nextServiceDue;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _kmController.text = widget.vehicle.currentKm.toString();
    _plateController.text = widget.vehicle.plate;
    _maxController.text = widget.vehicle.maxKm.toString();
    _modelController.text = widget.vehicle.model;
    _selectedInspectorId = widget.vehicle.assignedInspector?.id;
    _selectedInspectorName = widget.vehicle.assignedInspector?.name;
    _lastServiceDate = widget.vehicle.lastServiceDate;
    _nextServiceDue = widget.vehicle.nextServiceDue;
  }

  @override
  void dispose() {
    _kmController.dispose();
    _plateController.dispose();
    _modelController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isLastService) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isLastService
          ? (_lastServiceDate ?? DateTime.now())
          : (_nextServiceDue ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              surface: AppColors.primaryDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isLastService) {
          _lastServiceDate = picked;
        } else {
          _nextServiceDue = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(
        title: widget.vehicle.plate,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _deleteVehicleDialog(context),
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleInfoSection(),
              const SizedBox(height: 16),
              _buildMileageSection(),
              const SizedBox(height: 16),
              _buildServiceSection(),
              const SizedBox(height: 16),
              _buildInspectorSection(),
              const SizedBox(height: 32),
              if (_isEditing) _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
    return _buildSection(
      title: 'Vehicle Information',
      icon: Icons.directions_car,
      children: [
        _buildEditableField(
          label: LocaleKeys.plate.tr(),
          controller: _plateController,
          icon: Icons.confirmation_number,
          enabled: _isEditing,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Plate is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Model',
          controller: _modelController,
          icon: Icons.car_rental,
          enabled: _isEditing,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Model is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMileageSection() {
    final currentKm =
        int.tryParse(_kmController.text) ?? widget.vehicle.currentKm;
    final maxKm = widget.vehicle.maxKm;
    final remainingKm = maxKm - currentKm;
    final usagePercent = ((currentKm / maxKm) * 100).clamp(0, 100).toInt();

    return _buildSection(
      title: 'Mileage Details',
      icon: Icons.speed,
      children: [
        _buildEditableField(
          label: LocaleKeys.current_km.tr(),
          controller: _kmController,
          icon: Icons.my_location,
          suffix: 'km',
          enabled: _isEditing,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Current kilometer is required';
            }
            final km = int.tryParse(value);
            if (km == null || km < 0) {
              return LocaleKeys.invalid_km_value.tr();
            }
            if (km > maxKm) {
              return 'Cannot exceed maximum kilometer';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildEditableField(
          controller: _maxController,
          label: LocaleKeys.max_km.tr(),
          icon: Icons.flag,
          suffix: 'km',
          enabled: _isEditing,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Maximum kilometer is required';
            }
            final km = int.tryParse(value);
            if (km == null || km < 0) {
              return LocaleKeys.invalid_km_value.tr();
            }

            // ✅ Ensure max >= current
            final currentKm = int.tryParse(_kmController.text);
            if (currentKm != null && km < currentKm) {
              return 'Maximum kilometer cannot be less than current kilometer';
            }

            return null; // ✅ Valid case
          },
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          label: LocaleKeys.remaining_km.tr(),
          value: '$remainingKm km',
          icon: Icons.trending_down,
          color: remainingKm < 1000 ? Colors.red : Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildProgressCard(
          label: LocaleKeys.used_percentage.tr(),
          percent: usagePercent,
        ),
      ],
    );
  }

  Widget _buildServiceSection() {
    final lastService = _lastServiceDate ?? widget.vehicle.lastServiceDate;
    final nextService = _nextServiceDue ?? widget.vehicle.nextServiceDue;
    final daysUntilService = nextService.difference(DateTime.now()).inDays;

    return _buildSection(
      title: 'Service Schedule',
      icon: Icons.build,
      children: [
        _buildDateField(
          label: 'Last Service',
          date: lastService,
          icon: Icons.history,
          enabled: _isEditing,
          onTap: _isEditing ? () => _selectDate(context, true) : null,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Next Service Due',
          date: nextService,
          icon: Icons.event,
          enabled: _isEditing,
          onTap: _isEditing ? () => _selectDate(context, false) : null,
          subtitle: daysUntilService > 0
              ? '$daysUntilService days remaining'
              : 'Service overdue!',
          subtitleColor: daysUntilService > 7 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildInspectorSection() {
    return _buildSection(
      title: 'Inspector Assignment',
      icon: Icons.person,
      children: [
        _buildInspectorCard(),
        if (_isEditing) ...[
          const SizedBox(height: 16),
          _buildInspectorActionButtons(),
        ],
      ],
    );
  }

  Widget _buildInspectorCard() {
    final hasInspector =
        _selectedInspectorId != null && _selectedInspectorId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasInspector
              ? AppColors.primaryRed.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasInspector
                  ? AppColors.primaryRed.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasInspector ? Icons.person : Icons.person_off,
              color: hasInspector ? AppColors.primaryRed : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Inspector',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedInspectorName ?? 'Unassigned',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing)
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }

  Widget _buildInspectorActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              final inspectors = context.read<ProviderAdminUsers>().inspectors;
              _showInspectorSelectionSheet(inspectors);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              side: BorderSide(color: AppColors.primaryRed),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.person_search, size: 20),
            label: const Text('Select Inspector'),
          ),
        ),
        if (_selectedInspectorId != null &&
            _selectedInspectorId!.isNotEmpty) ...[
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedInspectorId = null;
                _selectedInspectorName = null;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.person_remove, size: 20),
          ),
        ],
      ],
    );
  }

  void _showInspectorSelectionSheet(List<UserModel> inspectors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(20),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              color: Colors.white.withValues(alpha: 0.3),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No inspectors available',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: inspectors.length,
                        itemBuilder: (context, index) {
                          final inspector = inspectors[index];
                          final inspectorId = inspector.id;
                          final inspectorName = inspector.name;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedInspectorId == inspectorId
                                    ? AppColors.primaryRed
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryRed
                                    .withValues(alpha: 0.2),
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                              title: Text(
                                inspectorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: _selectedInspectorId == inspectorId
                                  ? Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryRed,
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedInspectorId = inspectorId;
                                  _selectedInspectorName = inspectorName;
                                });
                                Navigator.pop(context);
                              },
                            ),
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    String? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: AppColors.primaryRed),
        suffixText: suffix,
        suffixStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required IconData icon,
    required bool enabled,
    VoidCallback? onTap,
    String? subtitle,
    Color? subtitleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryRed, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            subtitleColor ??
                            Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (enabled)
              Icon(
                Icons.edit_calendar,
                color: Colors.white.withValues(alpha: 0.3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

  Widget _buildProgressCard({required String label, required int percent}) {
    Color progressColor;
    if (percent < 50) {
      progressColor = Colors.green;
    } else if (percent < 80) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return AppButton(
      onPressed: _isSaving ? null : _saveChanges,
      isLoading: _isSaving,
      icon: Icons.save,
      text: 'Save Changes',
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Parse new values
      final newKm = int.parse(_kmController.text);
      final maxKm = int.parse(_maxController.text);
      final newPlate = _plateController.text.trim();
      final newModel = _modelController.text.trim();

      // Get old values
      final oldInspectorId = widget.vehicle.assignedInspector?.id;

      // Check what changed
      final kmChanged = newKm != widget.vehicle.currentKm;
      final plateChanged = newPlate != widget.vehicle.plate;
      final maxKmChanged = maxKm != widget.vehicle.maxKm;
      final modelChanged = newModel != widget.vehicle.model;
      final datesChanged =
          _lastServiceDate != widget.vehicle.lastServiceDate ||
          _nextServiceDue != widget.vehicle.nextServiceDue;

      // Inspector changed check
      final inspectorChanged = _selectedInspectorId != oldInspectorId;

      // If nothing changed, just exit
      if (!kmChanged &&
          !inspectorChanged &&
          !plateChanged &&
          !maxKmChanged &&
          !modelChanged &&
          !datesChanged) {
        if (!mounted) return;
        showSnakBarr(context, "No changes detected");
        setState(() => _isSaving = false);
        return;
      }

      // Prepare inspector ID to pass (only if changed)
      String? inspectorIdToPass;
      if (inspectorChanged) {
        // If unselecting inspector, pass empty string
        if (_selectedInspectorId == null || _selectedInspectorId!.isEmpty) {
          inspectorIdToPass = ''; // Empty string means unassign
        } else {
          inspectorIdToPass = _selectedInspectorId; // New inspector ID
        }
      }

      console('Inspector Changed: $inspectorChanged');
      console('Old Inspector: $oldInspectorId');
      console('New Inspector: $_selectedInspectorId');
      console('Passing Inspector ID: $inspectorIdToPass');

      // Call the batch update method
      await context.read<ProviderAdminVehicles>().updateVehicleWithBatch(
        vehicleId: widget.vehicle.id,
        newKm: kmChanged ? newKm : null,
        newPlate: plateChanged ? newPlate : null,
        newModel: modelChanged ? newModel : null,
        newInspectorId: inspectorIdToPass,
        newInspectorName: inspectorChanged ? _selectedInspectorName : null,
        oldInspectorId: oldInspectorId,
        lastServiceDate: datesChanged ? _lastServiceDate : null,
        nextServiceDue: datesChanged ? _nextServiceDue : null,
        maxKm: maxKm, // ALWAYS pass maxKm, not conditionally
      );

      if (!mounted) return;
      showSnakBarr(context, "Vehicle updated successfully");
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showSnakBarr(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteVehicleDialog(BuildContext context) async {
    final assignedInspector = widget.vehicle.assignedInspector;
    final hasInspector = assignedInspector?.id != null;
    final inspectorName = assignedInspector?.name ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Delete Vehicle', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          hasInspector
              ? 'This vehicle is currently assigned to inspector "$inspectorName".\n\n'
                    'Deleting it will also remove it from the inspector’s history.\n\n'
                    'Are you sure you want to proceed?'
              : 'Are you sure you want to delete this vehicle?\n\n'
                    'This action cannot be undone.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          Consumer<ProviderAdminVehicles>(
            builder: (context, provider, _) {
              return TextButton(
                onPressed: provider.isLoading
                    ? null
                    : () => Navigator.pop(context, true),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Text('Delete', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<ProviderAdminVehicles>();

      await provider.deleteVehicle(
        vehicleId: widget.vehicle.id,
        inspectorId: assignedInspector?.id,
        context: context,
        inspectorName: inspectorName,
      );
    }
  }
}
