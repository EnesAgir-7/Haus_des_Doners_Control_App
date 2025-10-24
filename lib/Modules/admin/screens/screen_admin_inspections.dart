import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/screens/screen_inspection_details.dart';
import '../admin_providers/provider_admin_inspections.dart';
import '../widgets/admin_inspection_card.dart';

class ScreenAdminInspections extends StatefulWidget {
  const ScreenAdminInspections({super.key});

  @override
  State<ScreenAdminInspections> createState() => _ScreenAdminInspectionsState();
}

class _ScreenAdminInspectionsState extends State<ScreenAdminInspections> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderAdminInspections>().initialize();
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
      context.read<ProviderAdminInspections>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
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
          child: Consumer<ProviderAdminInspections>(
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

  Widget _buildHeader(ProviderAdminInspections provider) {
    return Row(
      children: [
        Icon(Icons.fact_check, color: Colors.lightBlueAccent),
        SizedBox(width: 6),
        Text(
          "Inspections",
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          " (Page-${provider.pageNo.toString()})",
          style: TextStyle(fontSize: 10),
        ),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${provider.inspections.length} Total",
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

  Widget _buildSearchBar(ProviderAdminInspections provider) {
    return TextField(
      onChanged: provider.setSearchQuery,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "${LocaleKeys.search.tr()} by branch name...",
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

  Widget _buildSortOptions(ProviderAdminInspections provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          _buildSortChip(
            label: "By Date",
            value: AppConstants.date,
            icon: Icons.calendar_today,
            provider: provider,
          ),
          _buildSortChip(
            label: LocaleKeys.sort_by_score.tr(),
            value: AppConstants.score,
            icon: Icons.star,
            provider: provider,
          ),
          _buildSortChip(
            label: "By Branch",
            value: AppConstants.branch,
            icon: Icons.apartment,
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
    required ProviderAdminInspections provider,
  }) {
    final isSelected = provider.sortBy == value;
    return GestureDetector(
      onTap: () => provider.setSortBy(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildInspectionList(ProviderAdminInspections provider) {
    if (provider.isLoading && provider.inspections.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (provider.errorMessage != null && provider.inspections.isEmpty) {
      return _buildErrorState(provider);
    }

    if (provider.inspections.isEmpty) {
      return _buildEmptyState(provider);
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AppColors.primaryRed,
      backgroundColor: AppColors.lightBlack,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(bottom: 50),
        physics: AlwaysScrollableScrollPhysics(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryRed,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState(ProviderAdminInspections provider) {
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

  Widget _buildEmptyState(ProviderAdminInspections provider) {
    return Center(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check, size: 80, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              provider.searchQuery.isNotEmpty
                  ? "No Inspections found"
                  : LocaleKeys.no_inspections_yet.tr(),
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
}
