import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../translations/locale_keys.g.dart';
import '../../admin/widgets/admin_inspection_card.dart';
import '../../inspector/screens/screen_inspection_details.dart';
import '../branch_providers/provider_branch_inspections.dart';

class ScreenBranchInspections extends StatefulWidget {
  const ScreenBranchInspections({super.key});

  @override
  State<ScreenBranchInspections> createState() =>
      _ScreenBranchInspectionsState();
}

class _ScreenBranchInspectionsState extends State<ScreenBranchInspections> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBranchInspections>().initialize(
        branchId: loggedInUser?.id,
      );
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<ProviderBranchInspections>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Consumer<ProviderBranchInspections>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(provider),
                    const SizedBox(height: 12),
                    _buildSortOptions(provider),
                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 12),
                    Expanded(child: _buildInspectionList(provider)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ProviderBranchInspections provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fact_check,
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
                  LocaleKeys.inspection_history.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${provider.inspections.length} ${LocaleKeys.total_inspections.tr()}",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (provider.pageNo > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryRed.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                "${LocaleKeys.page.tr()} ${provider.pageNo}",
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSortOptions(ProviderBranchInspections provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSortChip(
            label: "Latest",
            value: AppConstants.date,
            icon: Icons.calendar_today,
            provider: provider,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: "Highest Score",
            value: AppConstants.score,
            icon: Icons.star,
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
    required ProviderBranchInspections provider,
  }) {
    final isSelected = provider.sortBy == value;
    return GestureDetector(
      onTap: () => provider.setSortBy(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed
              : AppColors.primaryDark.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryRed
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionList(ProviderBranchInspections provider) {
    if (provider.isLoading && provider.inspections.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (provider.errorMessage != null && provider.inspections.isEmpty) {
      return _buildErrorState(provider);
    }

    if (provider.inspections.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AppColors.primaryRed,
      backgroundColor: AppColors.lightBlack,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 50),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.inspections.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.inspections.length) {
            return _buildLoadingIndicator();
          }

          final inspection = provider.inspections[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ScreenInspectionDetails(inspectionId: inspection.id),
              ),
            ),
            child: AdminInspectionCard(inspection: inspection),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryRed,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState(ProviderBranchInspections provider) {
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
              provider.errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(LocaleKeys.try_again.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  size: 64,
                  color: Colors.white24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                LocaleKeys.no_inspections_yet.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "It looks like there are no inspections for this branch yet. ",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
