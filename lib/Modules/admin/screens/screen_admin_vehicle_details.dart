import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/vehicle_model.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../admin_providers/provider_admin_fleet.dart';
import '../../../translations/locale_keys.g.dart';
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
    Future.microtask(() {
      context.read<ProviderAdminUsers>().streamAllInspectors();
    });
  }

  void _initializeControllers() {
    _kmController.text = widget.vehicle.currentKm.toString();
    _plateController.text = widget.vehicle.plate;
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
              const SizedBox(height: 20),
              _buildMileageSection(),
              const SizedBox(height: 20),
              _buildServiceSection(),
              const SizedBox(height: 20),
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
        _buildInfoCard(
          label: LocaleKeys.max_km.tr(),
          value: '$maxKm km',
          icon: Icons.flag,
          color: Colors.blue,
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
              final inspectors = context
                  .read<ProviderAdminUsers>()
                  .inspectors
                  .where((i) => i.active)
                  .toList();
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

  void _showInspectorSelectionSheet(List<dynamic> inspectors) {
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
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.5),
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newKm = int.parse(_kmController.text);

      // Update vehicle kilometers
      await context.read<ProviderAdminFleet>().updateVehicleKilometers(
        widget.vehicle.id,
        newKm,
      );

      // Handle inspector assignment changes
      if (_selectedInspectorId != widget.vehicle.assignedInspector?.id) {
        if (_selectedInspectorId == null || _selectedInspectorId!.isEmpty) {
          await context.read<ProviderAdminFleet>().unassignInspector(
            widget.vehicle.id,
          );
        } else {
          await context.read<ProviderAdminFleet>().assignInspector(
            widget.vehicle.id,
            _selectedInspectorId!,
            _selectedInspectorName!,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Vehicle updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
