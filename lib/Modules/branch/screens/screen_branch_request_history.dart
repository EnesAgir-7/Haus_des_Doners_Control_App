import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import '../../../models/branch_update_request_model.dart';
import '../branch_providers/provider_branch_update_request.dart';
import 'screen_branch_request_details.dart';

class ScreenBranchRequestHistory extends StatefulWidget {
  final String branchId;
  const ScreenBranchRequestHistory({Key? key, required this.branchId})
    : super(key: key);

  @override
  State<ScreenBranchRequestHistory> createState() =>
      _ScreenBranchRequestHistoryState();
}

class _ScreenBranchRequestHistoryState
    extends State<ScreenBranchRequestHistory> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchUpdateRequestProvider>().loadRequestHistory(
        widget.branchId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: LocaleKeys.request_history.tr()),
      body: Consumer<BranchUpdateRequestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.requestHistory.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }

          if (provider.requestHistory.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => provider.loadRequestHistory(widget.branchId),
            color: AppColors.primaryRed,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.requestHistory.length,
              itemBuilder: (context, index) {
                final request = provider.requestHistory[index];
                return _buildRequestCard(request);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.no_requests_found.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScreenBranchRequestDetails(request: request),
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            request.isPending
                ? Icons.pending_actions
                : request.isApproved
                ? Icons.check_circle
                : Icons.cancel,
            color: statusColor,
          ),
        ),
        title: Text(
          request.isPending
              ? LocaleKeys.status_pending.tr()
              : request.isApproved
              ? LocaleKeys.status_approved.tr()
              : LocaleKeys.status_rejected.tr(),
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${request.changeCount} ${request.changeCount == 1 ? LocaleKeys.change.tr() : LocaleKeys.changes.tr()}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat.yMMMd().add_Hm().format(request.requestedAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }
}
