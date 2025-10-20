import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/vehicle_model.dart';
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
  final _kmController = TextEditingController();
  bool _isEditing = false;

  String? _selectedInspectorId;

  @override
  void initState() {
    super.initState();
    _kmController.text = widget.vehicle.currentKm.toString();
    _selectedInspectorId = widget.vehicle.assignedInspectorId;
    Future.microtask(() {
      context.read<ProviderAdminUsers>().loadUsers('');
    });
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.plate),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                await _saveChanges();
                setState(() {
                  _isEditing = false;
                });
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: LocaleKeys.branch_information.tr(),
              children: [
                _buildInfoRow(LocaleKeys.plate.tr(), widget.vehicle.plate),
                _buildInfoRow('Model', widget.vehicle.model),
                _buildInfoRow(
                  LocaleKeys.current_km.tr(),
                  '${widget.vehicle.currentKm} km',
                  controller: _kmController,
                ),
                _buildInfoRow(
                  LocaleKeys.max_km.tr(),
                  '${widget.vehicle.maxKm} km',
                ),
                _buildInfoRow(
                  LocaleKeys.remaining_km.tr(),
                  '${widget.vehicle.remainingKm} km',
                ),
                _buildInfoRow(
                  LocaleKeys.used_percentage.tr(),
                  '${widget.vehicle.usagePercent}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: LocaleKeys.inspection_details.tr(),
              children: [
                _buildInfoRow(
                  LocaleKeys.last_inspected.tr(),
                  DateFormat.yMMMd().format(widget.vehicle.lastServiceDate),
                ),
                _buildInfoRow(
                  LocaleKeys.service_due.tr(),
                  DateFormat.yMMMd().format(widget.vehicle.nextServiceDue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: LocaleKeys.inspection_details.tr(),
              children: [
                _buildInfoRow(
                  'Status',
                  widget.vehicle.status,
                  dropdown: !_isEditing
                      ? null
                      : DropdownButtonFormField<String>(
                          initialValue: widget.vehicle.status,
                          items: const [
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'passive',
                              child: Text('Passive'),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value != null) {
                              await context
                                  .read<ProviderAdminFleet>()
                                  .updateVehicleStatus(
                                    widget.vehicle.id,
                                    value,
                                  );
                            }
                          },
                        ),
                ),
                _buildInfoRow(
                  'Assigned Inspector',
                  widget.vehicle.assignedInspectorName ?? 'Unassigned',
                  dropdown: !_isEditing
                      ? null
                      : Consumer<ProviderAdminUsers>(
                          builder: (context, provider, child) {
                            final inspectors = provider.inspectors;
                            return DropdownButtonFormField<String>(
                              initialValue: _selectedInspectorId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('Unassigned'),
                                ),
                                ...inspectors.where((i) => i.active).map((
                                  inspector,
                                ) {
                                  return DropdownMenuItem(
                                    value: inspector.id,
                                    child: Text(inspector.name),
                                  );
                                }),
                              ],
                              onChanged: (value) async {
                                setState(() {
                                  _selectedInspectorId = value;
                                });
                                if (value == null || value.isEmpty) {
                                  await _unassignInspector();
                                } else {
                                  final inspector = inspectors.firstWhere(
                                    (i) => i.id == value,
                                  );
                                  await _assignInspector(
                                    inspector.id,
                                    inspector.name,
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignInspector(
    String inspectorId,
    String inspectorName,
  ) async {
    try {
      await context.read<ProviderAdminFleet>().assignInspector(
        widget.vehicle.id,
        inspectorId,
        inspectorName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _unassignInspector() async {
    await context.read<ProviderAdminFleet>().unassignInspector(
      widget.vehicle.id,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _saveChanges() async {
    final newKm = int.tryParse(_kmController.text);
    if (newKm == null) return;

    await context.read<ProviderAdminFleet>().updateVehicleKilometers(
      widget.vehicle.id,
      newKm,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    TextEditingController? controller,
    Widget? dropdown,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child:
                dropdown ??
                (_isEditing && controller != null
                    ? TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      )
                    : Text(value, style: const TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }
}
