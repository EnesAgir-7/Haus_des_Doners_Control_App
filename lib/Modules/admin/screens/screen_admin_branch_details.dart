import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:haus_des_control/Modules/admin/widgets/admin_location_picker.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/core/extensions.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../helpers/app_helpers.dart';
import '../../../models/branch_model.dart';
import '../../../models/route_model.dart';
import '../../../models/user_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/app_button.dart';
import '../../inspector/widgets/custom_toast.dart';
import '../admin_firebase_services/admin_template_service.dart';
import '../admin_providers/provider_admin_branches.dart';
import '../widgets/admin_branch_chart.dart';
import '../widgets/admin_template_selection_sheet.dart';
import '../widgets/widgets_admin_branch_details.dart';
import 'screen_admin_inspections.dart';

class ScreenAdminBranchDetails extends StatefulWidget {
  final BranchModel branch;

  const ScreenAdminBranchDetails({super.key, required this.branch});

  @override
  State<ScreenAdminBranchDetails> createState() =>
      _ScreenAdminBranchDetailsState();
}

class _ScreenAdminBranchDetailsState extends State<ScreenAdminBranchDetails> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _regionController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;

  bool _isEditing = false;
  bool _isLoadingDetails = true;
  String? _detailsError;

  // Location data
  double? _latitude;
  double? _longitude;

  final TemplateHelper _templateHelper = TemplateHelper();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch.name);
    _addressController = TextEditingController(text: widget.branch.address);
    _regionController = TextEditingController(text: widget.branch.region ?? '');
    _contactNameController = TextEditingController(
      text: widget.branch.contactName,
    );
    _contactPhoneController = TextEditingController(
      text: widget.branch.contactPhone,
    );

    // Initialize lat/lng if available
    _latitude = widget.branch.gps.latitude;
    _longitude = widget.branch.gps.longitude;

    _loadBranchDetails();
  }

  Future<void> _loadBranchDetails() async {
    try {
      setState(() {
        _isLoadingDetails = true;
        _detailsError = null;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detailsError = e.toString();
          _isLoadingDetails = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      _nameController.text = widget.branch.name;
      _addressController.text = widget.branch.address;
      _regionController.text = widget.branch.region ?? '';
      _contactNameController.text = widget.branch.contactName;
      _contactPhoneController.text = widget.branch.contactPhone;
      _latitude = widget.branch.gps.latitude;
      _longitude = widget.branch.gps.longitude;
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveChanges() async {
    final provider = context.read<ProviderAdminBranches>();
    try {
      final updatedBranch = widget.branch.copyWith(
        name: _nameController.text,
        address: _addressController.text,
        region: _regionController.text.isEmpty ? null : _regionController.text,
        contactName: _contactNameController.text,
        contactPhone: _contactPhoneController.text,
        gps: (_latitude != null && _longitude != null)
            ? GeoPoint(_latitude!, _longitude!)
            : widget.branch.gps,
      );

      await provider.updateBranch(updatedBranch);

      if (mounted) {
        setState(() => _isEditing = false);
        showSnakBarr(context, "Branch updated successfully");
      }
    } catch (e) {
      if (mounted) showSnakBarr(context, 'Error: $e');
    }
  }

  Future<void> _pickLocationFromMap() async {
    final result = await showLocationPickerDialog(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
      googleMapsApiKey: dotenv.env['GOOGLE_MAPS_KEY']!,
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _regionController.text = result['address'].toString();
      });
    }
  }

  Future<void> _deleteBranch() async {
    final nameController = TextEditingController();

    // 🟡 Check if branch is already in inspector's route
    if (widget.branch.stop != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.lightBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Branch in Route',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            'This branch is currently part of ${widget.branch.assignedInspector!.name} route.\n\n'
            'It cannot be deleted until the route is completed or removed.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      );
      return;
    }

    // 🟢 Normal delete flow if branch.stop == null
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Delete Branch', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. To confirm, please type the branch name:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              widget.branch.name,
              style: TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter branch name',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.primaryDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryRed),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          Consumer<ProviderAdminBranches>(
            builder: (context, provider, _) {
              return TextButton(
                onPressed: provider.isLoading
                    ? null
                    : () {
                        if (nameController.text.trim() ==
                            widget.branch.name.trim()) {
                          Navigator.pop(context, true);
                        } else {
                          showSnakBarr(context, 'Branch name does not match');
                        }
                      },
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

    if (confirmed == true && mounted) {
      final provider = context.read<ProviderAdminBranches>();
      try {
        await provider.deleteBranch(
          branchId: widget.branch.id,
          inspectorId: widget.branch.assignedInspector?.id,
        );
        if (mounted) {
          Navigator.pop(context);
          showSnakBarr(context, 'Branch deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          showSnakBarr(context, 'Error deleting branch: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          if (!_isEditing)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              color: AppColors.lightBlack,
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteBranch();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Delete Branch',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: _toggleEdit,
          ),
          if (_isEditing)
            Consumer<ProviderAdminBranches>(
              builder: (context, provider, _) {
                return IconButton(
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  onPressed: provider.isLoading ? null : _saveChanges,
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryRed.withValues(alpha: 0.08),
              AppColors.primaryDark,
              AppColors.primaryDark,
            ],
            stops: const [0.0, 0.25, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoadingDetails
              ? _buildLoadingState()
              : _buildContent(isTablet),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppColors.primaryRed),
    );
  }

  Widget _buildContent(bool isTablet) {
    if (_detailsError != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadBranchDetails,
      color: AppColors.primaryRed,
      backgroundColor: AppColors.lightBlack,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactHeader(),
        const SizedBox(height: 16),
        _buildStatsGrid(),
        const SizedBox(height: 16),
        _buildQuickInfoCard(),
        const SizedBox(height: 16),
        _buildContactCard(),
        const SizedBox(height: 16),
        if (!widget.branch.haveNoScores) ...[
          buildBranchPerformanceChart(widget.branch.last12MonthsScores),
          const SizedBox(height: 16),
        ],
        _buildInspectorCard(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildCompactHeader(),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 20),
                  if (!widget.branch.haveNoScores)
                    buildBranchPerformanceChart(
                      widget.branch.last12MonthsScores,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildQuickInfoCard(),
                  const SizedBox(height: 20),
                  _buildContactCard(),
                  const SizedBox(height: 20),
                  _buildInspectorCard(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed.withValues(alpha: 0.15),
            AppColors.lightBlack,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.branch.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.branch.address,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildCompactStatusBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusBadge() {
    Color color;
    IconData icon;

    switch (widget.branch.status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'inactive':
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildStatsGrid() {
    final performancePercent = 100 - widget.branch.averageScore;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildCompactStatCard(
          label: LocaleKeys.total_inspections.tr(),
          value: widget.branch.totalInspections.toString(),
          icon: Icons.fact_check_outlined,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScreenAdminInspections(branch: widget.branch),
            ),
          ),
        ),
        _buildCompactStatCard(
          label: 'Performance',
          value: '${performancePercent.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: getBranchPerformanceColor(performancePercent),
        ),
        _buildCompactStatCard(
          label: 'Last Inspection',
          value: widget.branch.daysSinceLastInspection != null
              ? '${widget.branch.daysSinceLastInspection}d'
              : 'Never',
          icon: Icons.schedule,
          color: widget.branch.daysSinceLastInspection != null
              ? _getUrgencyColor(widget.branch.daysSinceLastInspection!)
              : Colors.grey,
        ),
        _buildCompactStatCard(
          label: 'Last Score',
          value: widget.branch.lastInspectionScore ?? 'N/A',
          icon: Icons.star,
          color: widget.branch.lastInspectionScore != null
              ? getScoreColor(widget.branch.lastInspectionScore!)
              : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildCompactStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Branch Info',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCompactField(
            label: LocaleKeys.subsidiaries.tr(),
            controller: _nameController,
            enabled: _isEditing,
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 12),
          _buildCompactField(
            label: LocaleKeys.region.tr(),
            controller: _addressController,
            enabled: _isEditing,
            icon: Icons.location_city,
          ),
          const SizedBox(height: 12),
          // Location Picker
          !_isEditing
              ? SizedBox.shrink()
              : InkWell(
                  onTap: _isEditing ? _pickLocationFromMap : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isEditing
                          ? AppColors.primaryDark.withValues(alpha: 0.6)
                          : AppColors.primaryDark.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isEditing
                            ? AppColors.primaryRed.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.map,
                          color: _isEditing
                              ? AppColors.primaryRed
                              : Colors.white38,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _regionController.text.isEmpty
                                    ? 'Tap to pick from map'
                                    : _regionController.text,
                                style: TextStyle(
                                  color: _isEditing
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (_isEditing)
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.primaryRed,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          // Template Selection
          InkWell(
            onTap: _showTemplateSelectionSheet,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Questionnaire',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.branch.templateName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryRed,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Contact',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCompactField(
            label: LocaleKeys.branch_representative.tr(),
            controller: _contactNameController,
            enabled: _isEditing,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildCompactField(
            label: 'Phone',
            controller: _contactPhoneController,
            enabled: _isEditing,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Created',
            widget.branch.createdAt.getFormattedDateTime(),
            Icons.event,
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.assigned_to.tr(),
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.branch.assignedInspector == null)
            _buildEmptyInspector()
          else
            _buildAssignedInspector(),
        ],
      ),
    );
  }

  Widget _buildEmptyInspector() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Icon(Icons.person_off_outlined, size: 40, color: Colors.white24),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.unassigned.tr(),
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Assign Inspector',
            onPressed: _showAssignInspectorDialog,
            padding: const EdgeInsets.symmetric(vertical: 12),
            borderRadius: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedInspector() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryRed,
                child: Text(
                  widget.branch.assignedInspector!.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.branch.assignedInspector!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.branch.stop != null)
                Tooltip(
                  message: 'In Route',
                  child: Icon(Icons.route, color: Colors.green, size: 20),
                )
              else
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: _unassignInspector,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (widget.branch.stop == null)
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Change Inspector',
              onPressed: _showAssignInspectorDialog,
              padding: const EdgeInsets.symmetric(vertical: 12),
              borderRadius: 10,
            ),
          )
        else
          Column(
            children: [
              Text(
                '⚠️ Branch is in an active route',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRouteStopInfo(widget.branch.stop!),
                  icon: Icon(Icons.route, size: 18),
                  label: Text('View Route'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white24),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCompactField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.primaryDark.withValues(alpha: 0.6)
            : AppColors.primaryDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(
        //   color: enabled
        //       ? AppColors.primaryRed.withValues(alpha: 0.3)
        //       : Colors.white.withValues(alpha: 0.1),
        // ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white70,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? AppColors.primaryRed : Colors.white54,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? AppColors.primaryRed : Colors.white38,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: AppColors.primaryRed),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.error_occurred.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _detailsError!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBranchDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
              ),
              child: Text(LocaleKeys.try_again.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return TemplateSelectionSheet(
          templateHelper: _templateHelper,
          onTemplateSelected: (template) async {
            final provider = context.read<ProviderAdminBranches>();

            final bool done = await provider.updateBrachTemplate(
              branchId: widget.branch.id,
              templateId: template.id,
              templateName: template.name,
            );

            if (mounted && done) {
              widget.branch.templateId = template.id;
              widget.branch.templateName = template.name;
              setState(() {});
              showSnakBarr(context, "Template updated successfully");
            } else if (mounted) {
              showSnakBarr(context, "Error updating template");
            }
          },
        );
      },
    );
  }

  void _showRouteStopInfo(RouteStopModel stop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => AdminStopInfoSheet(stop: stop),
    );
  }

  Future<void> _showAssignInspectorDialog() async {
    final provider = context.read<ProviderAdminBranches>();

    try {
      final inspectors = context.read<ProviderAdminUsers>().inspectors;

      if (!mounted) return;

      if (inspectors.isEmpty) {
        showSnakBarr(context, 'No available inspectors');
        return;
      }

      final selected = await showModalBottomSheet<UserModel>(
        context: context,
        backgroundColor: AppColors.lightBlack,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Inspector',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: inspectors.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final inspector = inspectors[index];
                        return InkWell(
                          onTap: () => Navigator.pop(context, inspector),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryRed,
                                  child: Text(
                                    inspector.name[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inspector.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        inspector.serviceAccount,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (inspector.region != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      inspector.region!,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      if (selected != null && mounted) {
        try {
          final success = await provider.assignInspectorToBranch(
            branchId: widget.branch.id,
            inspectorId: selected.id,
            inspectorName: selected.name,
            oldInspectorId: widget.branch.assignedInspector?.id,
          );

          if (success) {
            widget.branch.assignedInspector = AssignedInspector(
              id: selected.id,
              name: selected.name,
            );
            setState(() {});
            if (mounted) {
              showSnakBarr(context, 'Inspector assigned successfully');
            }
          } else {
            if (mounted) {
              showSnakBarr(context, 'Failed to assign inspector');
            }
          }
        } catch (e) {
          if (mounted) {
            showSnakBarr(context, 'Error: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showSnakBarr(context, 'Error loading inspectors: $e');
      }
    }
  }

  Future<void> _unassignInspector() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Unassign Inspector',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to unassign this inspector?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Unassign',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await context
            .read<ProviderAdminBranches>()
            .unassignInspectorFromBranch(
              branchId: widget.branch.id,
              inspectorId: widget.branch.assignedInspector!.id,
            );

        if (success) {
          widget.branch.assignedInspector = null;
          setState(() {});
          if (mounted) {
            showSnakBarr(context, 'Inspector unassigned successfully');
          }
        } else {
          if (mounted) {
            showSnakBarr(context, 'Failed to unassign inspector');
          }
        }
      } catch (e) {
        if (mounted) {
          showSnakBarr(context, 'Error: $e');
        }
      }
    }
  }

  Color _getUrgencyColor(int days) {
    if (days == 0) return Colors.green;
    if (days <= 7) return Colors.lightGreen;
    if (days <= 30) return Colors.orange;
    return Colors.red;
  }

 
}
