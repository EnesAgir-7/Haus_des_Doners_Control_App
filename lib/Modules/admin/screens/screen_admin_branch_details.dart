import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/core/extensions.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/branch_model.dart';
import '../../../models/route_model.dart';
import '../../../models/user_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/app_button.dart';
import '../../inspector/widgets/custom_toast.dart';
import '../admin_firebase_services/admin_template_service.dart';
import '../admin_providers/provider_admin_branches.dart';
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
    _loadBranchDetails();
  }

  Future<void> _loadBranchDetails() async {
    try {
      setState(() {
        _isLoadingDetails = true;
        _detailsError = null;
      });

      // If you need to fetch additional details from provider
      // final provider = context.read<ProviderAdminBranches>();
      // await provider.loadBranchDetails(widget.branch.id);

      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate loading

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
      );

      await provider.updateBranch(updatedBranch);

      if (mounted) {
        setState(() => _isEditing = false);
        showSnakBarr(context, LocaleKeys.inspection_saved_successfully.tr());
      }
    } catch (e) {
      if (mounted) {
        showSnakBarr(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        actions: [
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
                      : const Icon(Icons.save, color: Colors.white),
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
          child: _isLoadingDetails ? _buildLoadingState() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppColors.primaryRed),
    );
  }

  Widget _buildContent() {
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
          // _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 16),
                  _buildStatsCards(),
                  const SizedBox(height: 16),
                  _buildBasicInfoSection(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  _buildContactInfoSection(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  _buildInspectionHistorySection(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  if (!widget.branch.haveNoScores) ...[
                    _buildPerformanceChart(),
                    const SizedBox(height: 16),
                  ],
                  _buildAssignedInspectorSection(),
                  const SizedBox(height: 80),
                ],
              ),
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

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.branch.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.branch.address,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (widget.branch.region != null)
                  Text(
                    widget.branch.region!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (widget.branch.status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        text = 'Active';
        break;
      case 'inactive':
        color = Colors.grey;
        text = 'Inactive';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      default:
        color = Colors.grey;
        text = widget.branch.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.branch.status.toLowerCase() == 'active'
                ? Icons.check_circle
                : Icons.info,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final performancePercent = widget.branch.averageScore;
    final reversedPercent = 100 - performancePercent;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                ontap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ScreenAdminInspections(branch: widget.branch),
                    ),
                  );
                },
                label: LocaleKeys.total_inspections.tr(),
                value: widget.branch.totalInspections.toString(),
                icon: Icons.fact_check_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Performance',
                value: '${reversedPercent.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: _getPerformanceColor(reversedPercent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Last Inspection',
                value: widget.branch.lastInspectionDate != null
                    ? '${widget.branch.daysSinceLastInspection} days ago'
                    : 'Never',
                icon: Icons.history,
                color: widget.branch.daysSinceLastInspection != null
                    ? _getUrgencyColor(widget.branch.daysSinceLastInspection!)
                    : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Last Score',
                value: widget.branch.lastInspectionScore ?? 'N/A',
                icon: Icons.star_outline,
                color: widget.branch.lastInspectionScore != null
                    ? _getScoreColor(widget.branch.lastInspectionScore!)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? ontap,
  }) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightRed,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 8),
            Text(
              LocaleKeys.about_the_branch.tr(),
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoField(
          label: LocaleKeys.subsidiaries.tr(),
          controller: _nameController,
          enabled: _isEditing,
          icon: Icons.business,
        ),
        const SizedBox(height: 12),
        _buildInfoField(
          label: LocaleKeys.region.tr(),
          controller: _addressController,
          enabled: _isEditing,
          icon: Icons.location_on,
        ),

        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            _showTemplateSelectionSheet();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  "Questionnaire",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.branch.templateName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Change Questionnaire",
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 1. Define the handler function (if not already defined):
  void _showTemplateSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryDark,
      builder: (context) {
        return TemplateSelectionSheet(
          templateHelper: _templateHelper,
          onTemplateSelected: (template) async {
            final provider = context.read<ProviderAdminBranches>();
            print('Template Selected: ${template.id}');

            final bool done = await provider.updateBrachTemplate(
              branchId: widget.branch.id,
              templateId: template.id,
              templateName: template.name,
            );
            if (mounted && done) {
              widget.branch.templateId = template.id;
              widget.branch.templateName = template.name;
              _loadBranchDetails();

              showSnakBarr(
                context,
                "Branch template changed to: ${template.name}",
              );
            } else {
              showSnakBarr(context, "Error while changing the template");
            }
          },
        );
      },
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.contacts_outlined,
              color: AppColors.primaryRed,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              LocaleKeys.branch_information.tr(),
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoField(
          label: LocaleKeys.branch_representative.tr(),
          controller: _contactNameController,
          enabled: _isEditing,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        _buildInfoField(
          label: 'Phone',
          controller: _contactPhoneController,
          enabled: _isEditing,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildInspectionHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 8),
            Text(
              LocaleKeys.inspection_details.tr(),
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.branch.lastInspectionDate != null) ...[
          _buildInfoTile(
            label: LocaleKeys.last_inspected.tr(),
            value: widget.branch.lastInspectionDate!.getFormattedDateTime(),
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            label: 'Days Since Last Inspection',
            value: '${widget.branch.daysSinceLastInspection} days',
            icon: Icons.timeline,
            valueColor: _getUrgencyColor(
              widget.branch.daysSinceLastInspection ?? 0,
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white54, size: 20),
                const SizedBox(width: 12),
                Text(
                  'No inspection yet',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _buildInfoTile(
          label: LocaleKeys.assigned_at.tr(),
          value: widget.branch.createdAt.getFormattedDateTime(),

          icon: Icons.event,
        ),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    // Parse scores and extract actual values
    final List<Map<String, dynamic>> parsedScores = [];
    double maxActualScore = 0;

    for (var s in widget.branch.last12MonthsScores!) {
      if (s.contains('/')) {
        final parts = s.split('/');
        final score = double.tryParse(parts.first.trim()) ?? 0.0;
        final max = double.tryParse(parts.last.trim()) ?? 100.0;
        final percentage = (max > 0) ? (score / max) * 100 : 0.0;

        parsedScores.add({
          'score': score,
          'maxScore': max,
          'percentage': percentage,
          'displayText': s,
        });

        if (score > maxActualScore) maxActualScore = score;
      } else {
        final score = double.tryParse(s) ?? 0.0;
        parsedScores.add({
          'score': score,
          'maxScore': 100.0,
          'percentage': score,
          'displayText': score.toStringAsFixed(0),
        });

        if (score > maxActualScore) maxActualScore = score;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Last 12 Inspections',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              // Max score indicator
              if (maxActualScore > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Oldest ← → Latest',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        'Scale: 0-${maxActualScore.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              // Chart with SingleChildScrollView to prevent overflow
              SizedBox(
                height: 240,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  physics: NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 240,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(parsedScores.length, (index) {
                        final item = parsedScores[index];
                        final score = item['score'] as double;
                        final maxScore = item['maxScore'] as double;
                        final percentage = item['percentage'] as double;

                        final invertedPercentage = 100 - percentage;
                        final height = (invertedPercentage / 100) * 160;

                        // Color based on percentage (lower score = green)
                        final color = _getPerformanceColor(invertedPercentage);

                        // Calculate month number (1 = oldest, 12 = latest)
                        final monthNumber = index + 1;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Score label
                                if (score > 0)
                                  Container(
                                    height: 32,
                                    alignment: Alignment.bottomCenter,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          score.toStringAsFixed(0),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                        ),
                                        if (maxScore != 100)
                                          Text(
                                            '/${maxScore.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 7,
                                            ),
                                            maxLines: 1,
                                          ),
                                      ],
                                    ),
                                  )
                                else
                                  SizedBox(height: 32),

                                const SizedBox(height: 4),

                                // Bar
                                Container(
                                  height: height.clamp(4.0, 160.0).toDouble(),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        color,
                                        color.withValues(alpha: 0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Month number label
                                Container(
                                  height: 20,
                                  alignment: Alignment.topCenter,
                                  child: Text(
                                    monthNumber.toString(),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Legend with wrapped layout
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem(Colors.green, 'Excellent'),
                  _buildLegendItem(Colors.lightGreen, 'Good'),
                  _buildLegendItem(Colors.orange, 'Average'),
                  _buildLegendItem(Colors.red, 'Poor'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white54, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAssignedInspectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
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
          ],
        ),
        const SizedBox(height: 16),
        if (widget.branch.assignedInspector == null)
          _buildEmptyState(
            icon: Icons.person_off_outlined,
            message: LocaleKeys.unassigned.tr(),
            actionText: 'Assign Inspector',
            onAction: _showAssignInspectorDialog,
          )
        else
          Column(
            children: [
              _buildInspectorCard(widget.branch.assignedInspector!),
              const SizedBox(height: 12),
              widget.branch.stop == null
                  ? AppButton(
                      text: 'Change Inspector',
                      onPressed: _showAssignInspectorDialog,

                      padding: const EdgeInsets.symmetric(vertical: 12),
                      borderRadius: 10,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ This branch is already assigned to the route of inspector ${widget.branch.assignedInspector?.name} and cannot be removed until it is completed or manually removed from the route.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'To see the route details, click the button below.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        AppButton(
                          text: 'View Route Info',
                          onPressed: () =>
                              _showRouteStopInfo(widget.branch.stop!),

                          padding: const EdgeInsets.symmetric(vertical: 12),
                          borderRadius: 10,
                        ),
                      ],
                    ),
            ],
          ),
      ],
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
      builder: (context) {
        return AdminStopInfoSheet(stop: stop);
      },
    );
  }

  Widget _buildInspectorCard(AssignedInspector inspector) {
    return Consumer<ProviderAdminBranches>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  inspector.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              widget.branch.stop != null
                  ? Tooltip(
                      message: 'Already in Route',
                      child: Icon(Icons.route, color: Colors.green, size: 24),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: provider.isLoading
                          ? null
                          : () => _unassignInspector(),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: actionText,
            onPressed: onAction,
            backgroundColor: AppColors.primaryRed,
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            borderRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(
        //   color: enabled ? AppColors.primaryRed : Colors.white24,
        // ),
      ),
      child: TextField(
        readOnly: readOnly,
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(color: enabled ? Colors.white : Colors.white70),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? AppColors.primaryRed : Colors.white54,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? AppColors.primaryRed : Colors.white54,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
        builder: (context) => _buildSelectionSheet(
          title: 'Select Inspector',
          items: inspectors,
          itemBuilder: (UserModel inspector) => ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryRed,
              child: Text(
                inspector.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              inspector.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              inspector.serviceAccount,
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: inspector.region != null
                ? Container(
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
                      style: const TextStyle(color: Colors.blue, fontSize: 11),
                    ),
                  )
                : null,
            onTap: () => Navigator.pop(context, inspector),
          ),
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

            await _loadBranchDetails();

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

  Widget _buildSelectionSheet<T>({
    required String title,
    required List<T> items,
    required Widget Function(T) itemBuilder,
  }) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'No items available',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return itemBuilder(items[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
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
          'Are you sure you want to unassign the inspector from this branch?',
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

          await _loadBranchDetails();

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

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getUrgencyColor(int days) {
    if (days == 0) return Colors.green;
    if (days <= 7) return Colors.lightGreen;
    if (days <= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getScoreColor(String scoreString) {
    final parts = scoreString.split('/');
    if (parts.length != 2) return Colors.grey;

    final score = double.tryParse(parts.first) ?? 0.0;
    final maxScore = double.tryParse(parts.last) ?? 1.0;
    final percentage = (score / maxScore) * 100;

    // Reversed for German standard
    final reversedPercentage = 100 - percentage;

    if (reversedPercentage >= 80) return Colors.green;
    if (reversedPercentage >= 60) return Colors.lightGreen;
    if (reversedPercentage >= 40) return Colors.orange;
    return Colors.red;
  }
}
