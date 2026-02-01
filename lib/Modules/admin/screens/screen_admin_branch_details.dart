import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/core/extensions.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../common_services/user_selection_sheet.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../helpers/app_helpers.dart';
import '../../../models/branch_model.dart';
import '../../../models/route_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/app_button.dart';
import '../../inspector/widgets/custom_toast.dart';
import '../admin_providers/provider_admin_branches.dart';
import '../widgets/admin_branch_menu_button.dart';
import '../widgets/performance_chart.dart';
import '../widgets/widgets_admin_branch_details.dart';
import 'screen_admin_branch_docs.dart';
import 'screen_admin_branch_edit.dart';
import 'screen_admin_branch_notifications.dart';
import 'screen_admin_inspections.dart';
import '../../../common_services/excel_export_service.dart';
import '../../inspector/firebase_services/inspector_inspection_service.dart';

// ignore: must_be_immutable
class ScreenAdminBranchDetails extends StatefulWidget {
  BranchModel branch;

  ScreenAdminBranchDetails({super.key, required this.branch});

  @override
  State<ScreenAdminBranchDetails> createState() =>
      _ScreenAdminBranchDetailsState();
}

class _ScreenAdminBranchDetailsState extends State<ScreenAdminBranchDetails> {
  bool _isLoadingDetails = true;
  String? _detailsError;
  bool _isExporting = false;
  final InspectorInspectionService _inspectionService =
      InspectorInspectionService();

  @override
  void initState() {
    super.initState();
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

  Future<void> _deleteBranch() async {
    final nameController = TextEditingController();

    // Check if branch is in inspector's route
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
              const Icon(Icons.info_outline, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Text(
                LocaleKeys.branchInRoute.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            LocaleKeys.branchInRouteMessage.tr().replaceAll(
              '{inspectorName}',
              widget.branch.assignedInspector!.name,
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                LocaleKeys.ok.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Normal delete flow
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              LocaleKeys.deleteBranch.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.deleteConfirmationMessage.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.branch.name,
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.content_copy, color: Colors.white),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.branch.name));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: LocaleKeys.enterBranchName.tr(),
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
                  borderSide: const BorderSide(color: AppColors.primaryRed),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: const TextStyle(color: Colors.white70),
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
                          showSnakBarr(
                            context,
                            LocaleKeys.branchNameNotMatch.tr(),
                          );
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
                    : Text(
                        LocaleKeys.delete.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
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
          context: context,
          branchId: widget.branch.id,
          inspectorId: widget.branch.assignedInspector?.id,
        );
        if (mounted) {
          Navigator.pop(context);
          showSnakBarr(context, LocaleKeys.branchDeletedSuccess.tr());
        }
      } catch (e) {
        if (mounted) {
          showSnakBarr(context, '${LocaleKeys.errorDeletingBranch.tr()}: $e');
        }
      }
    }
  }

  Future _navigateToEditScreen() async {
    final BranchModel? newBranch = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenAdminEditBranch(branch: widget.branch),
      ),
    );

    if (newBranch != null) {
      widget.branch = newBranch;
      setState(() {});
    }
  }

  Future<void> _exportBranchInspections({int? limit, int? months}) async {
    setState(() => _isExporting = true);

    try {
      DateTime? since;
      String period = "";

      if (months != null) {
        since = DateTime.now().subtract(Duration(days: months * 30));
        period = months == 1 ? "Last Month" : "Last $months Months";
      } else if (limit != null) {
        period = "Last $limit Inspections";
      } else {
        period = "All Inspections";
      }

      final inspections = await _inspectionService
          .getInspectionsByBranchFiltered(
            branchId: widget.branch.id,
            limit: limit,
            since: since,
          );

      if (inspections.isEmpty) {
        if (mounted) {
          showSnakBarr(context, LocaleKeys.noData.tr());
        }
        return;
      }

      await ExcelExportService.exportBranchInspections(
        inspections: inspections,
        fileNamePrefix: '${widget.branch.name}_Report',
        shareTitle: 'Inspections Report - ${widget.branch.name}',
        branchName: widget.branch.name,
        period: period,
      );

      if (mounted) {
        showSnakBarr(context, 'Excel Report Exported Successfully');
      }
    } catch (e) {
      if (mounted) {
        showSnakBarr(context, 'Export Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.lightBlack,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Export Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Last N inspections
              _buildOptionCategory('By Count'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    'Last 10',
                    () => _exportBranchInspections(limit: 10),
                  ),
                  _buildOptionButton(
                    'Last 20',
                    () => _exportBranchInspections(limit: 20),
                  ),
                  _buildOptionButton(
                    'Last 30',
                    () => _exportBranchInspections(limit: 30),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Last X months
              _buildOptionCategory('By Time Period'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildOptionButton(
                    'Last Month',
                    () => _exportBranchInspections(months: 1),
                  ),
                  _buildOptionButton(
                    'Last 3 Months',
                    () => _exportBranchInspections(months: 3),
                  ),
                  _buildOptionButton(
                    'Last 6 Months',
                    () => _exportBranchInspections(months: 6),
                  ),
                  _buildOptionButton(
                    'Last Year',
                    () => _exportBranchInspections(months: 12),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCategory(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildOptionButton(String label, VoidCallback onSelected) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        onSelected();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          if (_isExporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.file_download_outlined,
                color: Colors.white,
              ),
              onPressed: _showExportOptionsSheet,
              tooltip: 'Export CSV',
            ),
          BranchMenuButton(
            onEdit: () {
              _navigateToEditScreen();
            },
            onDelete: () {
              _deleteBranch();
            },
            onSendNotification: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScreenAdminBranchNotifications(
                    branchId: widget.branch.id,
                    branchName: widget.branch.name,
                    fcmTokens: widget.branch.fcmTokens,
                  ),
                ),
              );
            },
            onUploadDocument: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScreenAdminDocumentsScreen(
                    branchId: widget.branch.id,
                    uploadedBy: loggedInUser!.id,
                    uploadedByName: loggedInUser!.name,
                  ),
                ),
              );
            },
            onTrainingVideos: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) =>
              //         ScreenAdminBranchTrainings(branchId: widget.branch.id),
              //   ),
              // );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingDetails
            ? _buildLoadingState()
            : _buildContent(isTablet),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
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
              // child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
              child: _buildMobileLayout(),
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
        if (widget.branch.branchEmail != null) ...[
          _buildEmailCard(),
          const SizedBox(height: 16),
        ],
        if (widget.branch.openingHours != null ||
            widget.branch.openingDays != null ||
            widget.branch.openingDay != null) ...[
          _buildOperatingHoursCard(),
          const SizedBox(height: 16),
        ],
        if (widget.branch.branchOwners != null &&
            widget.branch.branchOwners!.isNotEmpty) ...[
          _buildContactListCard(
            title: LocaleKeys.branchOwners.tr(),
            icon: Icons.business_center,
            contacts: widget.branch.branchOwners!,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.branch.branchManagers != null &&
            widget.branch.branchManagers!.isNotEmpty) ...[
          _buildContactListCard(
            title: LocaleKeys.branchManagers.tr(),
            icon: Icons.manage_accounts,
            contacts: widget.branch.branchManagers!,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.branch.suppliers != null &&
            widget.branch.suppliers!.isNotEmpty) ...[
          _buildContactListCard(
            title: LocaleKeys.suppliers.tr(),
            icon: Icons.local_shipping,
            contacts: widget.branch.suppliers!,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.branch.donerPrices != null ||
            widget.branch.software != null ||
            widget.branch.shopInformation != null) ...[
          _buildAdditionalInfoCard(),
          const SizedBox(height: 16),
        ],
        if (!widget.branch.haveNoScores) ...[
          _buildPerformanceSummary(),
          const SizedBox(height: 12),
          buildPerformanceChart(
            scores: widget.branch.last12MonthsScores!,
            title: LocaleKeys.last12Inspections.tr().replaceAll(
              "12",
              widget.branch.last12MonthsScores!.length.toString(),
            ),
            icon: Icons.bar_chart,
            subtitle: LocaleKeys.oldestToLatest.tr(),
          ),
          const SizedBox(height: 16),
        ],
        _buildInspectorCard(),
        const SizedBox(height: 80),
      ],
    );
  }

  // Widget _buildTabletLayout() {
  //   return Column(
  //     children: [
  //       _buildCompactHeader(),
  //       const SizedBox(height: 20),
  //       Row(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Expanded(
  //             flex: 3,
  //             child: Column(
  //               children: [
  //                 _buildStatsGrid(),
  //                 const SizedBox(height: 20),
  //                 if (!widget.branch.haveNoScores)
  //                   buildPerformanceChart(
  //                     scores: widget.branch.last12MonthsScores!,
  //                     title: LocaleKeys.last12Inspections.tr(),
  //                     icon: Icons.bar_chart,
  //                     subtitle: LocaleKeys.oldestToLatest.tr(),
  //                   ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(width: 20),
  //           Expanded(
  //             flex: 2,
  //             child: Column(
  //               children: [
  //                 _buildQuickInfoCard(),
  //                 const SizedBox(height: 20),
  //                 _buildContactCard(),
  //                 const SizedBox(height: 20),
  //                 _buildInspectorCard(),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 80),
  //     ],
  //   );
  // }

  Widget _buildPerformanceSummary() {
    final parsedScores = widget.branch.last12MonthsScores!
        .where((s) => s != '0' && s.contains('/'))
        .map((s) {
          try {
            // Use your global helper method instead of custom calculation
            final percentage = calculatePerformancePercent(s);
            return double.tryParse(percentage) ?? 0.0;
          } catch (e) {
            print('Error calculating percentage for: $s');
            return 0.0;
          }
        })
        .where((p) => p >= 0)
        .toList();

    if (parsedScores.isEmpty) return const SizedBox.shrink();

    final bestScore = parsedScores.reduce((a, b) => a > b ? a : b);
    final worstScore = parsedScores.reduce((a, b) => a < b ? a : b);
    final trend = parsedScores.length >= 2
        ? (parsedScores.last - parsedScores.first)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco.copyWith(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: AppColors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.twelveMonthSummary.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  LocaleKeys.best.tr(),
                  '${bestScore.toStringAsFixed(0)}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  LocaleKeys.worst.tr(),
                  '${worstScore.toStringAsFixed(0)}%',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  LocaleKeys.trend.tr(),
                  '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(0)}%',
                  trend >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  trend >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco,
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
                child: const Icon(
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
      case AppConstants.active:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AppConstants.inactive:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      case AppConstants.pending:
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
    return GridView.extent(
      maxCrossAxisExtent: 280,
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
          label: LocaleKeys.performance.tr(),
          value: '${widget.branch.averagePercent}%',
          icon: getPercentageIcon(
            double.tryParse(widget.branch.averagePercent) ?? 0,
          ),
          color: getPercentageColor(
            double.tryParse(widget.branch.averagePercent) ?? 0,
          ),
        ),
        _buildCompactStatCard(
          label: LocaleKeys.lastInspection.tr(),
          value: widget.branch.daysSinceLastInspection != null
              ? '${widget.branch.daysSinceLastInspection}d'
              : LocaleKeys.never.tr(),
          icon: Icons.schedule,
          color: widget.branch.daysSinceLastInspection != null
              ? _getUrgencyColor(widget.branch.daysSinceLastInspection!)
              : Colors.grey,
        ),
        _buildCompactStatCard(
          label: LocaleKeys.lastScore.tr(),
          value:
              widget.branch.lastInspectionScore ?? LocaleKeys.notAvailable.tr(),
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
        decoration: commonDeco,

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
      decoration: commonDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.branchInfo.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  LocaleKeys.branchId.tr(),
                  widget.branch.id,
                  Icons.tag,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.content_copy,
                  color: AppColors.primaryRed,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.branch.id));
                  showSnakBarr(context, LocaleKeys.copiedToClipboard.tr());
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          _buildInfoRow(
            LocaleKeys.status.tr(),
            widget.branch.status.toUpperCase(),
            Icons.circle,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            LocaleKeys.subsidiaries.tr(),
            widget.branch.name,
            Icons.business_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            LocaleKeys.region.tr(),
            widget.branch.address,
            Icons.location_city,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            LocaleKeys.gps.tr(),
            '${widget.branch.gps.latitude.toStringAsFixed(4)}, ${widget.branch.gps.longitude.toStringAsFixed(4)}',
            Icons.gps_fixed,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            LocaleKeys.questionnaire.tr(),
            widget.branch.templateName,
            Icons.description_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.contact_phone,
                color: AppColors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.contact.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            LocaleKeys.branch_representative.tr(),
            widget.branch.contactName,
            Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            LocaleKeys.phone.tr(),
            widget.branch.contactPhone,
            Icons.phone_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            LocaleKeys.created.tr(),
            widget.branch.createdAt.getFormattedDateTime(),
            Icons.event,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            LocaleKeys.lastUpdated.tr(),
            widget.branch.updatedAt.getFormattedDateTime(),
            Icons.update,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.email, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.branchEmail.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            LocaleKeys.emailAddress.tr(),
            widget.branch.branchEmail!,
            Icons.email_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHoursCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.operatingHours.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.branch.openingHours != null) ...[
            _buildInfoRow(
              LocaleKeys.openingTime.tr(),
              widget.branch.openingHours!.openingTime,
              Icons.access_time,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              LocaleKeys.closingTime.tr(),
              widget.branch.openingHours!.closingTime,
              Icons.access_time_filled,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.branch.openingDays != null &&
              widget.branch.openingDays!.isNotEmpty) ...[
            _buildInfoRow(
              '${LocaleKeys.openingDays.tr()}',
              "",
              Icons.calendar_month,
            ),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: widget.branch.openingDays!
                  .map<Widget>(
                    (day) => ChoiceChip(
                      label: Text(day),
                      selected: true,
                      avatar: null,
                      elevation: 3,
                      // padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.branch.openingDay != null) ...[
            _buildInfoRow(
              LocaleKeys.openingDay.tr(),
              DateFormat('dd/MM/yyyy').format(widget.branch.openingDay!),
              Icons.calendar_today,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactListCard({
    required String title,
    required IconData icon,
    required List<ContactPerson> contacts,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Title Row
          Row(
            children: [
              Icon(icon, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🔹 Horizontal contact list
          Scrollbar(
            interactive: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: contacts.map((contact) {
                  return _personCard(contact);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _personCard(ContactPerson contact) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryRed.withValues(alpha: 0.8),
                  AppColors.primaryRed.withValues(alpha: 0.4),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                // Role (if available)
                if (contact.role != null && contact.role!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      contact.role!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                // Phone
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),

                  child: Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          contact.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Tiny copy button
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: contact.phone));
                          showSnakBarr(
                            context,
                            LocaleKeys.copiedPhone.tr().replaceAll(
                              "{phone}",
                              contact.phone,
                            ),
                          );
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.copy,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.additionalInformation.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.branch.donerPrices != null) ...[
            _buildInfoRow(
              LocaleKeys.donerPrices.tr(),
              widget.branch.donerPrices!,
              Icons.attach_money,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.branch.software != null) ...[
            _buildInfoRow(
              LocaleKeys.software.tr(),
              widget.branch.software!,
              Icons.computer,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.branch.shopInformation != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.description,
                        color: Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        LocaleKeys.shopInformation.tr(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.branch.shopInformation!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInspectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: AppColors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.assigned_to.tr(),
                style: const TextStyle(
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
              const Icon(
                Icons.person_off_outlined,
                size: 40,
                color: Colors.white24,
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.unassigned.tr(),
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: LocaleKeys.assignInspector.tr(),
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
                  style: const TextStyle(
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
                  message: LocaleKeys.branchInRoute.tr(),
                  child: const Icon(Icons.route, color: Colors.green, size: 20),
                )
              else
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: _unassignInspector,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (widget.branch.stop == null)
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: LocaleKeys.changeInspector.tr(),
              onPressed: _showAssignInspectorDialog,
              padding: const EdgeInsets.symmetric(vertical: 12),
              borderRadius: 10,
            ),
          )
        else
          Column(
            children: [
              Text(
                LocaleKeys.branchInActiveRoute.tr(),
                style: const TextStyle(
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
                  icon: const Icon(Icons.route, size: 18),
                  label: Text(LocaleKeys.viewRoute.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final isMobile = ResponsiveBreakpoints.of(context).isTablet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: isMobile
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white38, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 4 : 0),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: isMobile ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: isMobile ? TextAlign.start : TextAlign.end,
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
            const Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.primaryRed,
            ),
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
      final selected = await showInspectorPicker(
        context: context,
        selectedInspectorId: widget.branch.assignedInspector?.id,
      );

      if (selected != null && mounted) {
        try {
          setState(() {
            _isLoadingDetails = true;
          });
          final success = await provider.assignInspectorToBranch(
            context: context,
            branchName: widget.branch.name,
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
            setState(() {
              _isLoadingDetails = false;
            });
            showSnakBarr(context, LocaleKeys.inspectorAssignedSuccess.tr());
          } else {
            showSnakBarr(context, LocaleKeys.failedToAssignInspector.tr());
          }
        } catch (e) {
          showSnakBarr(context, '$e');
        }
      }
    } catch (e) {
      showSnakBarr(context, '${LocaleKeys.errorLoadingInspectors.tr()} $e');
    }
  }

  Future<void> _unassignInspector() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          LocaleKeys.unassignInspector.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          LocaleKeys.unassignInspectorConfirm.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              LocaleKeys.unassign.tr(),
              style: const TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() {
          _isLoadingDetails = true;
        });
        final success = await context
            .read<ProviderAdminBranches>()
            .unassignInspectorFromBranch(
              branchName: widget.branch.name,
              branchId: widget.branch.id,
              inspectorId: widget.branch.assignedInspector!.id,
              context: context,
            );

        if (success) {
          widget.branch.assignedInspector = null;
          setState(() {
            _isLoadingDetails = false;
          });
          if (mounted) {
            showSnakBarr(context, LocaleKeys.inspectorUnassignedSuccess.tr());
          }
        } else {
          if (mounted) {
            showSnakBarr(context, LocaleKeys.failedToUnassignInspector.tr());
          }
        }
      } catch (e) {
        if (mounted) {
          showSnakBarr(context, '$e');
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
