import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/models/branch_model.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../helpers/app_helpers.dart';
import '../../providers/provider_branches.dart';
import '../../translations/locale_keys.g.dart';
import '../../widgets/app_button.dart';
import '../../widgets/inspector_branch_card.dart';
import '../common_methods.dart';
import 'control_page.dart';
import 'screen_map.dart';

class BranchesPage extends StatefulWidget {
  const BranchesPage({super.key});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
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
        ).push(MaterialPageRoute(builder: (context) => BranchMapScreen())),
        child: Icon(Icons.location_on, size: 36),
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
        Icon(Icons.apartment, color: Colors.lightBlueAccent),
        SizedBox(width: 6),
        Text(
          LocaleKeys.my_branches.tr(),
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            LocaleKeys.branch_count.tr().replaceAll(
              AppConstants.count,
              provider.branchCount.toString(),
            ),
            style: TextStyle(
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
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: LocaleKeys.search.tr(),
        hintStyle: TextStyle(color: Colors.white54),
        prefixIcon: Icon(Icons.search, color: Colors.white54),
        suffixIcon: provider.searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.white54),
                onPressed: () => provider.setSearchQuery(''),
              )
            : null,
        filled: true,
        fillColor: AppColors.lightBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryRed),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildSortOptions(ProviderBranches provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSortChip(
            label: LocaleKeys.sort_by_name.tr(),
            value: 'name',
            icon: Icons.sort_by_alpha,
            provider: provider,
          ),
          SizedBox(width: 8),
          _buildSortChip(
            label: LocaleKeys.sort_by_score.tr(),
            value: 'score',
            icon: Icons.star,
            provider: provider,
          ),
          SizedBox(width: 8),
          _buildSortChip(
            label: LocaleKeys.sort_by_last_control.tr(),
            value: 'lastInspection',
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : AppColors.lightBlack,
          borderRadius: BorderRadius.circular(20),
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
            SizedBox(width: 6),
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
      return Center(
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
        physics: AlwaysScrollableScrollPhysics(),
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
          Icon(Icons.error_outline, size: 60, color: AppColors.primaryRed),
          SizedBox(height: 16),
          Text(
            LocaleKeys.error_occurred.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
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
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apartment, size: 80, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              provider.searchQuery.isEmpty
                  ? LocaleKeys.no_branches_assigned.tr()
                  : LocaleKeys.branch_not_found.tr(),
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (provider.searchQuery.isNotEmpty) ...[
              SizedBox(height: 8),
              TextButton(
                onPressed: () => provider.setSearchQuery(''),
                child: Text(
                  LocaleKeys.clear_search.tr(),
                  style: TextStyle(color: AppColors.primaryRed),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          BranchDetailsSheet(branch: branchModel, provider: provider),
    );
  }
}

// Branch Details Bottom Sheet
class BranchDetailsSheet extends StatelessWidget {
  final BranchModel branch;
  final ProviderBranches provider;

  const BranchDetailsSheet({required this.branch, required this.provider});

  bool get isNextInspectionToday {
    if (branch.nextInspectionDate == null || branch.nextInspectionDate!.isEmpty)
      return false;

    return branch.nextInspectionDate ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              SizedBox(height: 12),
              _buildHeader(context),
              SizedBox(height: 16),
              _buildStatCards(),
              SizedBox(height: 16),
              if (branch.isRouteAssigned && branch.nextInspectionDate != null)
                _buildNextInspectionCard(),
              Divider(color: Colors.white24),
              SizedBox(height: 12),
              _buildInspectionHistoryHeader(),
              SizedBox(height: 12),
              Expanded(
                child: Consumer<ProviderBranches>(
                  builder: (context, co, _) =>
                      _buildInspectionHistory(scrollController),
                ),
              ),
              SizedBox(height: 16),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.white54),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      branch.address,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.white54),
                  SizedBox(width: 6),
                  Text(
                    '${branch.contactName} - ${branch.contactPhone}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: Colors.white),
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
            value: branch.averageScore.toStringAsFixed(1),
            icon: Icons.star,
            color: Colors.amber,
          ),
        ),
        SizedBox(width: 12),
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNextInspectionCard() {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
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
              Icon(Icons.next_plan, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Your Next Inspection",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: shadowDeco.copyWith(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isNextInspectionToday
                  ? "Today"
                  : formatTimeSlot(branch.nextInspectionDate.toString()),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionHistoryHeader() {
    return Text(
      "Last 10 Inspections",
      style: TextStyle(
        color: AppColors.primaryRed,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInspectionHistory(ScrollController scrollController) {
    if (provider.isLoadingInspections) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (provider.branchInspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              LocaleKeys.no_inspections_yet.tr(),
              style: TextStyle(color: Colors.white54),
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
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightRed,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Inspected by: ${inspection.inspectorName}",
                          style: TextStyle(
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
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getScoreColor(
                        inspection.score,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getScoreColor(inspection.score),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: _getScoreColor(inspection.score),
                        ),
                        SizedBox(width: 4),
                        Text(
                          inspection.score.toStringAsFixed(1),
                          style: TextStyle(
                            color: _getScoreColor(inspection.score),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (inspection.overallNotes.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  inspection.overallNotes,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<ProviderBranches>(
      builder: (context, prod, child) {
        // Show Start Inspection if assigned and today is inspection day
        if (branch.isRouteAssigned && isNextInspectionToday) {
          return Row(
            children: [
              Expanded(
                child: AppButton(
                  text: "Start Inspection",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ControlPage(
                          selectedBranch: branch,
                          branchId: branch.id,
                          branchTemplateId: branch.templateId,
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.green,
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  borderRadius: 10,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: "Edit Route",
                  onPressed: () => _showRouteManagementSheet(context, prod),
                  backgroundColor: AppColors.primaryRed,
                  textStyle: TextStyle(
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
          text: branch.isRouteAssigned ? "Edit Route" : "Add to Route",
          onPressed: () async {
            if (branch.isRouteAssigned) {
              _showRouteManagementSheet(context, prod);
            } else {
              await _handleAddToRoute(context, prod);
            }
          },
          backgroundColor: branch.isRouteAssigned
              ? AppColors.primaryRed
              : AppColors.amber,
          textStyle: TextStyle(
            color: branch.isRouteAssigned
                ? Colors.white
                : AppColors.primaryDark,
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
    final DateTime? pickedDate = await showDatePicker(
      locale: context.locale,
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (pickedDate != null) {
      final String timeSlot =
          "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";

      final success = await prod.assignBranchToMe(
        branchId: branch.id,
        branchName: branch.name,
        timeSlot: timeSlot,
        context: context,
        branchTemplateId: branch.templateId,
      );

      if (success && context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showRouteManagementSheet(BuildContext context, ProviderBranches prod) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          RouteManagementSheet(branch: branch, provider: prod),
    );
  }

  Color _getScoreColor(double score) {
    if (score <= 3.0) return Colors.green;
    if (score <= 7.0) return Colors.amber;
    return Colors.red;
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
      padding: EdgeInsets.all(20),
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
          SizedBox(height: 20),
          Icon(Icons.route, size: 48, color: AppColors.primaryRed),
          SizedBox(height: 16),
          Text(
            "Manage Route",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            branch.name,
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Consumer<ProviderBranches>(
            builder: (context, prod, child) {
              return Column(
                children: [
                  SizedBox(height: 12),
                  AppButton(
                    isLoading: prod.isLoading,
                    text: "Remove from Route",
                    onPressed: () async {
                      final success = await prod.unAssignBranchToMe(
                        branchId: branch.id,
                        context: context,
                      );

                      if (success && context.mounted) {
                        Navigator.pop(context); // Close route management sheet
                        Navigator.pop(context); // Close branch details sheet
                      }
                    },
                    backgroundColor: AppColors.primaryRed,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: 10,
                  ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
