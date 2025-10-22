import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/branch_model.dart';
import '../admin_providers/provider_admin_branches.dart';
import '../../../translations/locale_keys.g.dart';

class ScreenAdminBranchDetails extends StatefulWidget {
  final BranchModel branch;

  const ScreenAdminBranchDetails({super.key, required this.branch});

  @override
  State<ScreenAdminBranchDetails> createState() =>
      _ScreenAdminBranchDetailsState();
}

class _ScreenAdminBranchDetailsState extends State<ScreenAdminBranchDetails> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch.name);
    _addressController = TextEditingController(text: widget.branch.address);
    _contactNameController = TextEditingController(
      text: widget.branch.contactName,
    );
    _contactPhoneController = TextEditingController(
      text: widget.branch.contactPhone,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveBranch() async {
    final updatedBranch = widget.branch.copyWith(
      name: _nameController.text,
      address: _addressController.text,
      contactName: _contactNameController.text,
      contactPhone: _contactPhoneController.text,
    );

    await context.read<ProviderAdminBranches>().updateBranch(updatedBranch);
    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.inspection_saved_successfully.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch.name),
        backgroundColor: AppColors.primaryRed,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveBranch();
              } else {
                setState(() => _isEditing = true);
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
            _buildInfoCard(
              title: LocaleKeys.about_the_branch.tr(),
              children: [
                _buildInfoRow(
                  LocaleKeys.subsidiaries.tr(),
                  _nameController.text,
                  controller: _nameController,
                ),
                _buildInfoRow(
                  LocaleKeys.route.tr(),
                  _addressController.text,
                  controller: _addressController,
                ),
                _buildInfoRow('Status', widget.branch.status.toUpperCase()),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: LocaleKeys.branch_information.tr(),
              children: [
                _buildInfoRow(
                  LocaleKeys.branch_representative.tr(),
                  _contactNameController.text,
                  controller: _contactNameController,
                ),
                _buildInfoRow(
                  'Phone',
                  _contactPhoneController.text,
                  controller: _contactPhoneController,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: LocaleKeys.inspection_details.tr(),
              children: [
                _buildInfoRow(
                  LocaleKeys.assigned_to.tr(),
                  widget.branch.assignedInspector?.name ??
                      LocaleKeys.unassigned.tr(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: LocaleKeys.inspection_report.tr(),
              children: [
                _buildInfoRow(
                  LocaleKeys.total_inspections.tr(),
                  widget.branch.totalInspections.toString(),
                ),
                if (widget.branch.lastInspectionDate != null) ...[
                  _buildInfoRow(
                    LocaleKeys.last_inspected.tr(),
                    DateFormat(
                      'dd.MM.yyyy HH:mm',
                    ).format(widget.branch.lastInspectionDate!),
                  ),
                  _buildInfoRow(
                    LocaleKeys.score.tr(),
                    widget.branch.lastInspectionScore ??
                        '-',
                  ),
                ],
                _buildInfoRow(
                  LocaleKeys.average_score.tr(),
                  widget.branch.averageScore.toStringAsFixed(1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: LocaleKeys.inspection_details.tr(),
              children: [
                _buildInfoRow(
                  LocaleKeys.assigned_at.tr(),
                  DateFormat(
                    'dd.MM.yyyy HH:mm',
                  ).format(widget.branch.createdAt),
                ),
                _buildInfoRow(
                  LocaleKeys.last_inspected.tr(),
                  DateFormat(
                    'dd.MM.yyyy HH:mm',
                  ).format(widget.branch.updatedAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
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
