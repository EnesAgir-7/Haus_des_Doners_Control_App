import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/screens/screen_pdf_viewer.dart';
import 'package:haus_des_control/models/branch_model.dart';
import 'package:provider/provider.dart';

import '../../../common_services/remote_config_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../helpers/app_helpers.dart';
import '../../../translations/locale_keys.g.dart';
import '../../admin/screens/screen_admin_branch_edit.dart';
import '../providers/provider_branches.dart';
import '../widgets/app_button.dart';
import '../widgets/inspector_branch_card.dart';
import 'common_methods.dart';
import 'screen_map.dart';
import 'screen_submit_report.dart';

class ScreenBranches extends StatefulWidget {
  const ScreenBranches({super.key});

  @override
  State<ScreenBranches> createState() => _ScreenBranchesState();
}

class _ScreenBranchesState extends State<ScreenBranches> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBranches>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "branchesFab",
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const BranchMapScreen())),
        child: const Icon(Icons.location_on, size: 36),
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
          child: Consumer<ProviderBranches>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(provider),
                    const SizedBox(height: 12),
                    _buildSearchBar(provider),
                    const SizedBox(height: 12),
                    _buildSortOptions(provider),
                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 12),
                    Expanded(child: _buildBranchList(provider)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ProviderBranches provider) {
    return Row(
      children: [
        const Icon(Icons.apartment, color: Colors.lightBlueAccent),
        const SizedBox(width: 6),
        Text(
          LocaleKeys.my_branches.tr(),
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            LocaleKeys.branch_count.tr().replaceAll(
              AppConstants.count,
              provider.branchCount.toString(),
            ),
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ProviderBranches provider) {
    return TextField(
      onChanged: provider.setSearchQuery,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: LocaleKeys.search.tr(),
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: provider.searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () => provider.setSearchQuery(''),
              )
            : null,
        filled: true,
        fillColor: AppColors.lightBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRed),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildSortOptions(ProviderBranches provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          _buildSortChip(
            label: LocaleKeys.sort_by_name.tr(),
            value: AppConstants.name,
            icon: Icons.sort_by_alpha,
            provider: provider,
          ),
          _buildSortChip(
            label: LocaleKeys.sort_by_score.tr(),
            value: AppConstants.score,
            icon: Icons.star,
            provider: provider,
          ),
          _buildSortChip(
            label: LocaleKeys.byNextInspection.tr(),
            value: AppConstants.nextInspection,
            icon: Icons.access_time,
            provider: provider,
          ),
          _buildSortChip(
            label: LocaleKeys.sort_by_last_control.tr(),
            value: AppConstants.lastInspection,
            icon: Icons.access_time,
            provider: provider,
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required String value,
    required IconData icon,
    required ProviderBranches provider,
  }) {
    final isSelected = provider.sortBy == value;
    return GestureDetector(
      onTap: () => provider.setSortBy(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : AppColors.lightBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchList(ProviderBranches provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (provider.errorMessage != null) {
      return _buildErrorState(provider);
    }

    if (provider.branches.isEmpty) {
      return _buildEmptyState(provider);
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AppColors.primaryRed,
      backgroundColor: AppColors.lightBlack,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 50),
        key: const PageStorageKey('branchesList'),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.branches.length,
        itemBuilder: (context, index) {
          final branchModel = provider.branches[index];
          return GestureDetector(
            onTap: () => _showBranchDetails(context, branchModel, provider),
            child: InspectorBranchCard(branch: branchModel),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ProviderBranches provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppColors.primaryRed),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: Text(LocaleKeys.try_again.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ProviderBranches provider) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apartment, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isEmpty
                  ? LocaleKeys.no_branches_assigned.tr()
                  : LocaleKeys.branch_not_found.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (provider.searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => provider.setSearchQuery(''),
                child: Text(
                  LocaleKeys.clear_search.tr(),
                  style: const TextStyle(color: AppColors.primaryRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBranchDetails(
    BuildContext context,
    dynamic branchModel,
    ProviderBranches provider,
  ) {
    provider.selectBranch(branchModel);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          BranchDetailsSheet(branch: branchModel, provider: provider),
    );
  }
}

// Branch Details Bottom Sheet
// ignore: must_be_immutable
class BranchDetailsSheet extends StatelessWidget {
  BranchModel branch;
  final ProviderBranches provider;

  final remoteConfig = RemoteConfigService();

  BranchDetailsSheet({required this.branch, required this.provider});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 12),
              _buildHeader(context),
              if (remoteConfig.inspectorBranchEdit) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final BranchModel? newBranch = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScreenAdminEditBranch(branch: branch),
                      ),
                    );

                    if (newBranch != null) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(LocaleKeys.updateBranch.tr()),
                ),
              ],
              const SizedBox(height: 12),
              // SizedBox(height: 16),
              _buildStatCards(),
              const SizedBox(height: 16),
              if (branch.stop != null) _buildNextInspectionCard(),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              _buildInspectionHistoryHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<ProviderBranches>(
                  builder: (context, co, _) =>
                      _buildInspectionHistory(scrollController),
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branch.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.white54),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      branch.address,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.white54),
                  const SizedBox(width: 6),
                  Text(
                    '${branch.contactName} - ${branch.contactPhone}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: LocaleKeys.average_score.tr(),
            value: "${calculatePerformancePercent(branch.averageScore)}%",
            icon: getPercentageIcon(
              double.tryParse(
                    calculatePerformancePercent(branch.averageScore),
                  ) ??
                  0,
            ),
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer<ProviderBranches>(
            builder: (context, pro, child) {
              return _buildStatCard(
                label: LocaleKeys.total_inspections.tr(),
                value: branch.totalInspections.toString(),
                icon: Icons.fact_check,
                color: Colors.blue,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNextInspectionCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.next_plan, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.yourNextInspection.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: shadowDeco.copyWith(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              branch.isNextInspectionToday
                  ? LocaleKeys.today.tr()
                  : formatTimeSlot(branch.stop!.timeSlot.toString()),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionHistoryHeader() {
    return Text(
      LocaleKeys.last10Inspections.tr(),
      style: const TextStyle(
        color: AppColors.primaryRed,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInspectionHistory(ScrollController scrollController) {
    if (provider.isLoadingInspections) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (provider.branchInspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 60, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              LocaleKeys.no_inspections_yet.tr(),
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: provider.branchInspections.length,
      itemBuilder: (context, index) {
        final inspection = provider.branchInspections[index];
        final Color scoreColor = getScoreColor(inspection.score);

        return GestureDetector(
          onTap: () {
            if (inspection.pdfReportUrl == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    ScreenPdfViewer(pdfUrl: inspection.pdfReportUrl ?? ""),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightRed,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header Row — Inspector Info + Score + PDF Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Inspector Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleKeys.inspectedByYou.tr().replaceAll(
                              "You",
                              inspection.inspectorName ?? "",
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatDate(inspection.updatedAt),
                            style: TextStyle(
                              color: AppColors.whiteWithOpacity(.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scoreColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 14, color: scoreColor),
                          const SizedBox(width: 4),
                          Text(
                            inspection.score,
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Optional overall notes
                if (inspection.overallNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    inspection.overallNotes,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<ProviderBranches>(
      builder: (context, prod, child) {
        // Show Start Inspection if assigned and today is inspection day
        if (branch.stop != null && branch.isNextInspectionToday) {
          return Row(
            children: [
              Expanded(
                child: AppButton(
                  text: LocaleKeys.startInspection.tr(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScreenSubmitReport(
                          from: AppConstants.details,
                          selectedBranch: branch,
                          branchId: branch.id,
                          branchTemplateId: branch.templateId,
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.green,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  borderRadius: 10,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: LocaleKeys.manageRoute.tr(),
                  onPressed: () => _showRouteManagementSheet(context, prod),
                  backgroundColor: AppColors.primaryRed,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  borderRadius: 10,
                ),
              ),
            ],
          );
        }

        // Show Edit Route or Add to Route
        return AppButton(
          isLoading: prod.isLoading,
          text: branch.stop != null
              ? LocaleKeys.manageRoute.tr()
              : LocaleKeys.addToRoute.tr(),
          onPressed: () async {
            if (branch.stop != null) {
              _showRouteManagementSheet(context, prod);
            } else {
              await _handleAddToRoute(context, prod);
            }
          },
          backgroundColor: branch.stop != null
              ? AppColors.primaryRed
              : AppColors.amber,
          textStyle: TextStyle(
            color: branch.stop != null ? Colors.white : AppColors.primaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          borderRadius: 10,
        );
      },
    );
  }

  Future<void> _handleAddToRoute(
    BuildContext context,
    ProviderBranches prod,
  ) async {
    final String? pickedDate = await pickRouteDate(
      context,
      initialDate: DateTime.now(),
      maxDaysAhead: 7,
    );

    if (pickedDate != null) {
      final success = await prod.assignRouteToMe(
        branchId: branch.id,
        branchName: branch.name,
        branchAddress: branch.address,
        timeSlot: pickedDate, // formatted yyyy-MM-dd string
        context: context,
        branchTemplateId: branch.templateId,
      );

      if (success && context.mounted) {
        Navigator.pop(context); // close bottom sheet or dialog
      }
    }
  }

  void _showRouteManagementSheet(BuildContext context, ProviderBranches prod) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          RouteManagementSheet(branch: branch, provider: prod),
    );
  }
}

// Route Management Bottom Sheet
class RouteManagementSheet extends StatelessWidget {
  final BranchModel branch;
  final ProviderBranches provider;

  const RouteManagementSheet({required this.branch, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),
          const Icon(Icons.route, size: 48, color: AppColors.primaryRed),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.manageRoute.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            branch.name,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Consumer<ProviderBranches>(
            builder: (context, prod, child) {
              return Column(
                children: [
                  if (branch.stop != null &&
                      branch.stop?.status != AppConstants.completed)
                    AppButton(
                      isLoading: provider.isLoading,
                      text: LocaleKeys.updateSchedule.tr(),
                      onPressed: () async {
                        DateTime? initialDate;

                        try {
                          if (branch.stop?.timeSlot != null &&
                              branch.stop!.timeSlot.isNotEmpty) {
                            initialDate = DateTime.parse(branch.stop!.timeSlot);
                          }
                        } catch (_) {
                          initialDate = DateTime.now();
                        }

                        // 🗓️ Use the enhanced date picker
                        final String? pickedDate = await pickRouteDate(
                          context,
                          currentTimeSlot: branch.stop?.timeSlot,
                          initialDate: initialDate,
                          maxDaysAhead: 7,
                        );

                        if (pickedDate != null) {
                          // Call your provider method to update the stop schedule
                          final success = await provider
                              .updateStopTimeSlotForMe(
                                branchId: branch.stop!.branchId,
                                context: context,
                                newTimeSlot: pickedDate,
                                order: branch.stop!.order,
                              );

                          if (success && context.mounted) {
                            Navigator.pop(
                              context,
                            ); // Close route management sheet
                            Navigator.pop(context); // Close stop details sheet
                          }
                        }
                      },
                      backgroundColor: AppColors.amber,
                      textStyle: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      borderRadius: 10,
                    ),
                  const SizedBox(height: 12),
                  AppButton(
                    isLoading: prod.isLoading,
                    text: LocaleKeys.removeFromRoute.tr(),
                    onPressed: () async {
                      final success = await prod.unAssignMyRoute(
                        branchId: branch.id,
                        context: context,
                      );

                      if (success && context.mounted) {
                        Navigator.pop(context); // Close route management sheet
                        Navigator.pop(context); // Close branch details sheet
                      }
                    },
                    backgroundColor: AppColors.primaryRed,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: 10,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      LocaleKeys.cancel.tr(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
