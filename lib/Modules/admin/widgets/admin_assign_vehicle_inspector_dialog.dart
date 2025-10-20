import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/vehicle_model.dart';
import '../../../models/user_model.dart';
import '../admin_providers/provider_admin_users.dart';

class AssignVehicleInspectorDialog extends StatefulWidget {
  final VehicleModel vehicle;

  const AssignVehicleInspectorDialog({super.key, required this.vehicle});

  @override
  State<AssignVehicleInspectorDialog> createState() =>
      _AssignVehicleInspectorDialogState();
}

class _AssignVehicleInspectorDialogState
    extends State<AssignVehicleInspectorDialog> {
  String? _selectedInspectorId;

  @override
  void initState() {
    super.initState();
    _selectedInspectorId = widget.vehicle.assignedInspector?.id;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderAdminUsers>();
    final inspectors = provider.inspectors;

    return AlertDialog(
      title: Text('Assign Inspector to ${widget.vehicle.plate}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select an inspector to assign to this vehicle:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedInspectorId,
            decoration: const InputDecoration(
              labelText: 'Inspector',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Unassigned')),
              ...inspectors.where((i) => i.active).map((inspector) {
                return DropdownMenuItem(
                  value: inspector.id,
                  child: Text(inspector.name),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedInspectorId = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedInspectorId != widget.vehicle.assignedInspector?.id) {
              final selectedInspector = inspectors.firstWhere(
                (inspector) => inspector.id == _selectedInspectorId,
                orElse: () => UserModel(
                  id: '',
                  name: '',
                  serviceAccount: '',
                  role: '',
                  active: true,
                  region: '',
                  createdAt: DateTime.now().toString(),
                  updatedAt: DateTime.now().toString(),
                ),
              );

              Navigator.of(context).pop({
                'id': _selectedInspectorId ?? '',
                'name': selectedInspector.name,
              });
            } else {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
