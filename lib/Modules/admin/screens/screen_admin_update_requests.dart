import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart' as LK;
import 'package:provider/provider.dart';

import '../../../models/branch_update_request_model.dart';
import '../admin_providers/provider_admin_update_requests.dart';
import 'screen_admin_request_details.dart';

class ScreenAdminUpdateRequests extends StatefulWidget {
  const ScreenAdminUpdateRequests({Key? key}) : super(key: key);

  @override
  State<ScreenAdminUpdateRequests> createState() =>
      _ScreenAdminUpdateRequestsState();
}

class _ScreenAdminUpdateRequestsState extends State<ScreenAdminUpdateRequests> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUpdateRequestProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: LK.LocaleKeys.branch_update_requests.tr()),

      body: Consumer<AdminUpdateRequestProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Statistics Cards
              _buildStatsCards(provider),

              // Filter Tabs
              _buildFilterTabs(provider),

              // Requests List
              Expanded(child: _buildRequestsList(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(AdminUpdateRequestProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildStatItem(
            LK.LocaleKeys.pending.tr(),
            provider.pendingCount.toString(),
            Colors.orange,
            Icons.pending_actions_rounded,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            LK.LocaleKeys.approved.tr(),
            provider.approvedCount.toString(),
            Colors.green,
            Icons.check_circle_rounded,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            LK.LocaleKeys.rejected.tr(),
            provider.rejectedCount.toString(),
            Colors.red,
            Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildFilterTabs(AdminUpdateRequestProvider provider) {
    final filters = ['pending', 'approved', 'rejected', 'all'];
    final filterLabels = {
      'pending': LK.LocaleKeys.pending.tr(),
      'approved': LK.LocaleKeys.approved.tr(),
      'rejected': LK.LocaleKeys.rejected.tr(),
      'all': LK.LocaleKeys.all.tr(),
    };

    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.lightBlack.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: filters.map((filter) {
          final isSelected = provider.selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    filterLabels[filter]!,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestsList(AdminUpdateRequestProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (provider.filteredRequests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppColors.primaryRed,
      child: ListView.builder(
        padding: const EdgeInsets.all(6),
        itemCount: provider.filteredRequests.length,
        itemBuilder: (context, index) {
          final request = provider.filteredRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            LK.LocaleKeys.no_requests_found.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LK.LocaleKeys.requests_will_appear.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BranchUpdateRequestModel request) {
    final statusColor = request.isPending
        ? Colors.orange
        : request.isApproved
        ? Colors.green
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Indicator Bar
              Container(width: 5, color: statusColor),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ScreenRequestDetails(request: request),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.store_rounded,
                                  color: statusColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.branchName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${LK.LocaleKeys.by.tr()} ${request.requestedByName}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildCompactStatusBadge(
                                request.status,
                                statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_note_rounded,
                                  color: AppColors.primaryRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${request.changeCount} ${request.changeCount == 1 ? LK.LocaleKeys.change.tr() : LK.LocaleKeys.changes.tr()}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.access_time_filled_rounded,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getTimeAgo(request.requestedAt),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
      return LK.LocaleKeys.days_ago.tr(
        namedArgs: {'count': diff.inDays.toString()},
      );
    }
    if (diff.inHours > 0) {
      return LK.LocaleKeys.hours_ago.tr(
        namedArgs: {'count': diff.inHours.toString()},
      );
    }
    if (diff.inMinutes > 0) {
      return LK.LocaleKeys.minutes_ago.tr(
        namedArgs: {'count': diff.inMinutes.toString()},
      );
    }
    return LK.LocaleKeys.now.tr();
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return LK.LocaleKeys.status_pending.tr().toUpperCase();
      case 'approved':
        return LK.LocaleKeys.status_approved.tr().toUpperCase();
      case 'rejected':
        return LK.LocaleKeys.status_rejected.tr().toUpperCase();
      default:
        return status.toUpperCase();
    }
  }
}
