import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/branch_model.dart';
import '../../models/user_model.dart';
import '../../providers/provider_admin_branches.dart';

class AssignInspectorDialog extends StatefulWidget {
  final BranchModel branch;

  const AssignInspectorDialog({super.key, required this.branch});

  @override
  State<AssignInspectorDialog> createState() => _AssignInspectorDialogState();
}

class _AssignInspectorDialogState extends State<AssignInspectorDialog> {
  String? _selectedInspectorId;

  @override
  void initState() {
    super.initState();
    _selectedInspectorId = widget.branch.assignedInspector?.id;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderAdminBranches>();
    final inspectors = provider.inspectors;

    return AlertDialog(
      title: Text('Assign Inspector to ${widget.branch.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select an inspector to assign to this branch:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedInspectorId,
            decoration: const InputDecoration(
              labelText: 'Inspector',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Unassigned')),
              ...inspectors.map((inspector) {
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
          onPressed: () async {
            if (_selectedInspectorId != widget.branch.assignedInspector?.id) {
              await provider.assignInspectorToBranch(
                widget.branch.id,
                _selectedInspectorId ?? '',
              );
            }
            if (mounted) Navigator.of(context).pop();
          },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
