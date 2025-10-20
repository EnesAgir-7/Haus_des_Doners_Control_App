import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../admin_providers/provider_admin_fleet.dart';
import '../../translations/locale_keys.g.dart';

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
  String _status = 'active';

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
      appBar: AppBar(title: const Text('Create Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _plateController,
                decoration: InputDecoration(
                  labelText: LocaleKeys.plate.tr(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Plate is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: 'Model',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Model is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentKmController,
                decoration: InputDecoration(
                  labelText: LocaleKeys.current_km.tr(),
                  border: const OutlineInputBorder(),
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kilometer is required';
                  }
                  final km = int.tryParse(value);
                  if (km == null || km < 0) {
                    return LocaleKeys.invalid_km_value.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxKmController,
                decoration: InputDecoration(
                  labelText: LocaleKeys.max_km.tr(),
                  border: const OutlineInputBorder(),
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kilometer is required';
                  }
                  final maxKm = int.tryParse(value);
                  if (maxKm == null || maxKm < 0) {
                    return LocaleKeys.invalid_km_value.tr();
                  }
                  final currentKm =
                      int.tryParse(_currentKmController.text) ?? 0;
                  if (maxKm <= currentKm) {
                    return 'Maximum kilometer must be greater than current kilometer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'passive', child: Text('Passive')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Last Service'),
                subtitle: Text(DateFormat.yMMMd().format(_lastServiceDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Next Service'),
                subtitle: Text(DateFormat.yMMMd().format(_nextServiceDue)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _createVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Create Vehicle',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    final currentKm = int.parse(_currentKmController.text);
    final maxKm = int.parse(_maxKmController.text);
    final remainingKm = maxKm - currentKm;
    final usagePercent = ((currentKm / maxKm) * 100).round();
    final status = _status;

    try {
      await context.read<ProviderAdminFleet>().createVehicle(
        plate: _plateController.text,
        model: _modelController.text,
        currentKm: currentKm,
        maxKm: maxKm,
        remainingKm: remainingKm,
        usagePercent: usagePercent,
        lastServiceDate: _lastServiceDate,
        nextServiceDue: _nextServiceDue,
        status: status,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
