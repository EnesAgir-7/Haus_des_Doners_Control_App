import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/vehicle_model.dart';
import '../../providers/provider_admin_fleet.dart';
import '../../translations/locale_keys.g.dart';
import '../widgets/assign_vehicle_inspector_dialog.dart';

class AdminVehicleDetailsScreen extends StatefulWidget {
  final VehicleModel vehicle;
  const AdminVehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<AdminVehicleDetailsScreen> createState() =>
      _AdminVehicleDetailsScreenState();
}

class _AdminVehicleDetailsScreenState extends State<AdminVehicleDetailsScreen> {
  final _kmController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _kmController.text = widget.vehicle.currentKm.toString();
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
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
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
                _buildInfoRow('Status', widget.vehicle.status),
                if (widget.vehicle.assignedInspectorName != null) ...[
                  _buildInfoRow(
                    LocaleKeys.assigned_to.tr(),
                    widget.vehicle.assignedInspectorName!,
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: widget.vehicle.assignedInspectorId == null
                        ? _showAssignDialog
                        : _unassignInspector,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.vehicle.assignedInspectorId == null
                          ? AppColors.primaryRed
                          : Colors.grey,
                    ),
                    child: Text(
                      widget.vehicle.assignedInspectorId == null
                          ? LocaleKeys.assign_to_me.tr()
                          : LocaleKeys.unassign.tr(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) =>
          AssignVehicleInspectorDialog(vehicle: widget.vehicle),
    );

    if (result != null) {
      if (!mounted) return;
      await context.read<ProviderAdminFleet>().assignInspector(
        widget.vehicle.id,
        result['id']!,
        result['name']!,
      );
      if (!mounted) return;
      Navigator.pop(context);
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
            child: _isEditing && controller != null
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
                : Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
