import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../admin_providers/provider_admin_fleet.dart';

class ScreenAdminCreateVehicle extends StatefulWidget {
  const ScreenAdminCreateVehicle({super.key});

  @override
  State<ScreenAdminCreateVehicle> createState() =>
      _ScreenAdminCreateVehicleState();
}

class _ScreenAdminCreateVehicleState extends State<ScreenAdminCreateVehicle> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _currentKmController = TextEditingController();
  final _maxKmController = TextEditingController();
  DateTime _lastServiceDate = DateTime.now();
  DateTime _nextServiceDue = DateTime.now().add(const Duration(days: 30));
  bool _isCreating = false;

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    _currentKmController.dispose();
    _maxKmController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isLastService) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isLastService ? _lastServiceDate : _nextServiceDue,
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
      appBar: CustomAppBar(title: 'Create Vehicle'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Vehicle Information', Icons.info_outline),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _plateController,
                label: LocaleKeys.plate.tr(),
                icon: Icons.confirmation_number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Plate is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _modelController,
                label: 'Model',
                icon: Icons.directions_car,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Model is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Mileage Details', Icons.speed),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _currentKmController,
                label: LocaleKeys.current_km.tr(),
                icon: Icons.my_location,
                suffix: 'km',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Current kilometer is required';
                  }
                  final km = int.tryParse(value);
                  if (km == null || km < 0) {
                    return LocaleKeys.invalid_km_value.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _maxKmController,
                label: LocaleKeys.max_km.tr(),
                icon: Icons.flag,
                suffix: 'km',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Maximum kilometer is required';
                  }
                  final maxKm = int.tryParse(value);
                  if (maxKm == null || maxKm < 0) {
                    return LocaleKeys.invalid_km_value.tr();
                  }
                  final currentKm =
                      int.tryParse(_currentKmController.text) ?? 0;
                  if (maxKm <= currentKm) {
                    return 'Maximum kilometer must be greater than current';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Service Schedule', Icons.build),
              const SizedBox(height: 16),
              _buildDateTile(
                title: 'Last Service',
                date: _lastServiceDate,
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 12),
              _buildDateTile(
                title: 'Next Service',
                date: _nextServiceDue,
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 40),
              _buildCreateButton(),
            ],
          ),
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
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: AppColors.primaryRed),
        suffixText: suffix,
        suffixStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateTile({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
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
              child: Icon(
                Icons.calendar_today,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
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
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isCreating ? null : _createVehicle,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.5),
      ),
      child: _isCreating
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
                Icon(Icons.check_circle, size: 20),
                SizedBox(width: 8),
                Text(
                  'Create Vehicle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }

  Future<void> _createVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final currentKm = int.parse(_currentKmController.text);
    final maxKm = int.parse(_maxKmController.text);
    final remainingKm = maxKm - currentKm;
    final usagePercent = ((currentKm / maxKm) * 100).round();

    try {
      await context.read<ProviderAdminFleet>().createVehicle(
        plate: _plateController.text.trim(),
        model: _modelController.text.trim(),
        currentKm: currentKm,
        maxKm: maxKm,
        remainingKm: remainingKm,
        usagePercent: usagePercent,
        lastServiceDate: _lastServiceDate,
        nextServiceDue: _nextServiceDue,
      );

      if (!mounted) return;

      showSnakBarr(context, 'Vehicle created successfully');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      showSnakBarr(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
