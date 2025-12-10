import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:haus_des_control/Modules/admin/screens/screen_admin_add_branch.dart';
import 'package:provider/provider.dart';

import '../../../common_services/broadcast_notification_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../translations/locale_keys.g.dart';
import '../admin_providers/provider_admin_branches.dart';
import '../widgets/admin_all_branches_menu_button.dart';
import '../widgets/admin_branch_card.dart';
import 'screen_admin_update_requests.dart';

class ScreenAdminBranches extends StatefulWidget {
  const ScreenAdminBranches({super.key});

  @override
  State<ScreenAdminBranches> createState() => _ScreenAdminBranchesState();
}

class _ScreenAdminBranchesState extends State<ScreenAdminBranches> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderAdminBranches>().loadBranchStream();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildSortSection(),
          Expanded(child: _buildBranchList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScreenAdminAddBranch(),
            ),
          );
        },
        child: const Icon(Icons.add_business_outlined),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),

      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 12),
              BranchActionsMenuButton(
                onCreateAnnouncement: () {
                  showBroadcastNotificationDialog(
                    parentContext: context,
                    topic: AppConstants.branch,
                    recipientLabel: LocaleKeys.branches.tr(),
                  );
                },
                onUpdateRequests: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScreenAdminUpdateRequests(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatsRow(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: LocaleKeys.search.tr(),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: const Icon(Icons.search, color: AppColors.primaryRed),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () {
                  _searchController.clear();
                  context.read<ProviderAdminBranches>().setSearchQuery('');
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.primaryDark.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      onChanged: (value) {
        setState(() {});
        context.read<ProviderAdminBranches>().setSearchQuery(value);
      },
    );
  }

  Widget _buildStatsRow() {
    return Consumer<ProviderAdminBranches>(
      builder: (context, provider, _) {
        final totalBranches = provider.branches.length;
        final allBranches = provider.allBranches.length;

        return Row(
          children: [
            _buildStatCard(
              icon: Icons.store,
              label: LocaleKeys.totalBranches.tr(),
              value: allBranches.toString(),
              color: AppColors.primaryRed,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.filter_list,
              label: LocaleKeys.showing.tr(),
              value: totalBranches.toString(),
              color: Colors.blue,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortSection() {
    return Consumer<ProviderAdminBranches>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
          ),
          child: _buildSortOptions(provider),
        );
      },
    );
  }

  Widget _buildSortOptions(ProviderAdminBranches provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSortChip(
            label: LocaleKeys.sort_by_name.tr(),
            value: AppConstants.name,
            icon: Icons.sort_by_alpha,
            provider: provider,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: LocaleKeys.sort_by_score.tr(),
            value: AppConstants.score,
            icon: Icons.star,
            provider: provider,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: LocaleKeys.nextInspection.tr(),
            value: AppConstants.nextInspection,
            icon: Icons.event,
            provider: provider,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: LocaleKeys.sort_by_last_control.tr(),
            value: AppConstants.lastInspection,
            icon: Icons.history,
            provider: provider,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: LocaleKeys.region.tr(),
            value: AppConstants.region,
            icon: Icons.location_on,
            provider: provider,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: LocaleKeys.inspector.tr(),
            value: AppConstants.inspector,
            icon: Icons.person,
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
    required ProviderAdminBranches provider,
  }) {
    final isSelected = provider.sortBy == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => provider.setSortBy(value),
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primaryRed,
                      AppColors.primaryRed.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryRed
                  : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryRed.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, color: Colors.white, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchList() {
    return Consumer<ProviderAdminBranches>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryRed),
                const SizedBox(height: 16),
                Text(
                  LocaleKeys.loadingBranches.tr(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '${LocaleKeys.error.tr()}: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadBranchStream(),
                    icon: const Icon(Icons.refresh),
                    label: Text(LocaleKeys.retry.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final branches = provider.branches;
        if (branches.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _searchController.text.isNotEmpty
                          ? Icons.search_off
                          : Icons.store_outlined,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isNotEmpty
                          ? LocaleKeys.no_branches_found.tr()
                          : LocaleKeys.no_branches_available.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return MasonryGridView.extent(
          key: const PageStorageKey('branchesList'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          maxCrossAxisExtent: 800,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: branches.length,
          itemBuilder: (context, index) {
            return AdminBranchCard(branch: branches[index]);
          },
        );

        // ListView.separated(
        //   key: const PageStorageKey('branchesList'),
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   separatorBuilder: (context, index) => const SizedBox(height: 12),
        //   itemCount: branches.length,
        //   itemBuilder: (context, index) {
        //     final branch = branches[index];
        //     return AdminBranchCard(branch: branch);
        //   },
        // );
      },
    );
  }
}
