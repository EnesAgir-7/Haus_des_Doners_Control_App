import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:haus_des_control/Modules/admin/widgets/performance_chart.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../translations/locale_keys.g.dart';
import '../branch_providers/provider_branch_dashboard.dart';
import '../../../models/branch_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../helpers/app_helpers.dart';
import '../../../core/extensions.dart';

class BranchDetailsTab extends StatefulWidget {
  const BranchDetailsTab({super.key});

  @override
  State<BranchDetailsTab> createState() => _BranchDetailsTabState();
}

class _BranchDetailsTabState extends State<BranchDetailsTab> {
  late ProviderBranchDashboard provider;
  @override
  void initState() {
      provider = context.read<ProviderBranchDashboard>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.initialize();
    });
    super.initState();
    
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderBranchDashboard>();
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    final branch = provider.branchInfo;
    if (branch == null) {
      return Center(child: Text(LocaleKeys.branchNotFound.tr()));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactHeader(branch),
          const SizedBox(height: 16),
          _buildStatsGrid(context, branch),
          const SizedBox(height: 16),
          _buildQuickInfoCard(branch, context),
          const SizedBox(height: 16),
          _buildContactCard(branch),
          const SizedBox(height: 16),
          if (branch.branchEmail != null) ...[
            _buildEmailCard(branch),
            const SizedBox(height: 16),
          ],
          if (branch.openingHours != null ||
              branch.openingDays != null ||
              branch.openingDay != null) ...[
            _buildOperatingHoursCard(branch),
            const SizedBox(height: 16),
          ],
          if (branch.branchOwners != null &&
              branch.branchOwners!.isNotEmpty) ...[
            _buildContactListCard(
              title: LocaleKeys.branchOwners.tr(),
              icon: Icons.business_center,
              contacts: branch.branchOwners!,
            ),
            const SizedBox(height: 16),
          ],
          if (branch.branchManagers != null &&
              branch.branchManagers!.isNotEmpty) ...[
            _buildContactListCard(
              title: LocaleKeys.branchManagers.tr(),
              icon: Icons.manage_accounts,
              contacts: branch.branchManagers!,
            ),
            const SizedBox(height: 16),
          ],
          if (branch.suppliers != null && branch.suppliers!.isNotEmpty) ...[
            _buildContactListCard(
              title: LocaleKeys.suppliers.tr(),
              icon: Icons.local_shipping,
              contacts: branch.suppliers!,
            ),
            const SizedBox(height: 16),
          ],
          if (branch.donerPrices != null ||
              branch.software != null ||
              branch.shopInformation != null) ...[
            _buildAdditionalInfoCard(branch),
            const SizedBox(height: 16),
          ],
          // Performance summary (read-only)
          if (!branch.haveNoScores) ...[
            _buildPerformanceSummary(branch),
            const SizedBox(height: 12),
            buildPerformanceChart(
              scores: branch.last12MonthsScores ?? List.filled(12, '0'),
              title: LocaleKeys.last12Inspections.tr().replaceAll(
                '12',
                (branch.last12MonthsScores?.length ?? 12).toString(),
              ),
              icon: Icons.bar_chart,
              subtitle: LocaleKeys.oldestToLatest.tr(),
            ),
            const SizedBox(height: 16),
          ],
          _buildInspectorCard(branch),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(BranchModel branch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco,
      child: Row(
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
                  branch.name,
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
                  branch.address,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildCompactStatusBadge(branch.status),
        ],
      ),
    );
  }

  Widget _buildCompactStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
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

  Widget _buildStatsGrid(BuildContext context, BranchModel branch) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildCompactStatCard(
          LocaleKeys.total_inspections.tr(),
          branch.totalInspections.toString(),
          Icons.fact_check_outlined,
          Colors.blue,
        ),
        _buildCompactStatCard(
          LocaleKeys.performance.tr(),
          '${branch.averagePercent}%',
          Icons.bar_chart,
          Colors.green,
        ),
        _buildCompactStatCard(
          LocaleKeys.lastInspection.tr(),
          branch.daysSinceLastInspection != null
              ? '${branch.daysSinceLastInspection}d'
              : LocaleKeys.never.tr(),
          Icons.schedule,
          branch.daysSinceLastInspection != null
              ? _getUrgencyColor(branch.daysSinceLastInspection!)
              : Colors.grey,
        ),
        _buildCompactStatCard(
          LocaleKeys.lastScore.tr(),
          branch.lastInspectionScore ?? LocaleKeys.notAvailable.tr(),
          Icons.star,
          branch.lastInspectionScore != null
              ? getScoreColor(branch.lastInspectionScore!)
              : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildCompactStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: commonDeco.copyWith(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard(BranchModel branch, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco.copyWith(),
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
                LocaleKeys.about_the_branch.tr(),
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
              Expanded(child: _infoRow(LocaleKeys.branchId.tr(), branch.id)),
              IconButton(
                icon: const Icon(
                  Icons.content_copy,
                  color: AppColors.primaryRed,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: branch.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(LocaleKeys.copiedToClipboard.tr())),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(LocaleKeys.status.tr(), branch.status.toUpperCase()),
          const SizedBox(height: 12),
          _infoRow(LocaleKeys.subsidiaries.tr(), branch.name),
          const SizedBox(height: 12),
          _infoRow(LocaleKeys.region.tr(), branch.address),
          const SizedBox(height: 12),
          _infoRow(
            LocaleKeys.gps.tr(),
            '${branch.gps.latitude.toStringAsFixed(4)}, ${branch.gps.longitude.toStringAsFixed(4)}',
          ),
          const SizedBox(height: 12),
          _infoRow(LocaleKeys.questionnaire.tr(), branch.templateName),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white60)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(BranchModel branch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco.copyWith(),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(LocaleKeys.branch_representative.tr(), branch.contactName),
          const SizedBox(height: 12),
          _infoRow(LocaleKeys.phone.tr(), branch.contactPhone),
          const SizedBox(height: 12),
          _infoRow(
            LocaleKeys.created.tr(),
            branch.createdAt.getFormattedDateTime(),
          ),
          const SizedBox(height: 8),
          _infoRow(
            LocaleKeys.lastUpdated.tr(),
            branch.updatedAt.getFormattedDateTime(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard(BranchModel branch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco.copyWith(),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(LocaleKeys.emailAddress.tr(), branch.branchEmail ?? ''),
        ],
      ),
    );
  }

  Widget _buildOperatingHoursCard(BranchModel branch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco.copyWith(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.operatingHours.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (branch.openingHours != null) ...[
            _infoRow(
              LocaleKeys.openingTime.tr(),
              branch.openingHours!.openingTime,
            ),
            const SizedBox(height: 12),
            _infoRow(
              LocaleKeys.closingTime.tr(),
              branch.openingHours!.closingTime,
            ),
            const SizedBox(height: 12),
          ],
          if (branch.openingDays != null && branch.openingDays!.isNotEmpty) ...[
            _infoRow(LocaleKeys.openingDays.tr(), ''),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: branch.openingDays!
                  .map(
                    (d) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(d),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (branch.openingDay != null)
            _infoRow(
              LocaleKeys.openingDay.tr(),
              branch.openingDay!.toLocal().toString().split(' ').first,
            ),
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
      decoration: commonDeco.copyWith(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: contacts.length,
              itemBuilder: (context, index) => _personCard(contacts[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personCard(ContactPerson contact) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  contact.phone,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (contact.role != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    contact.role!,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(BranchModel branch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco.copyWith(),
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
                LocaleKeys.additionalInformation.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (branch.donerPrices != null)
            _infoRow(LocaleKeys.donerPrices.tr(), branch.donerPrices!),
          if (branch.software != null) ...[
            const SizedBox(height: 12),
            _infoRow(LocaleKeys.software.tr(), branch.software!),
          ],
          if (branch.shopInformation != null) ...[
            const SizedBox(height: 12),
            Text(
              branch.shopInformation!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary(BranchModel branch) {
    final parsedScores = branch.last12MonthsScores!
        .where((s) => s != '0' && s.contains('/'))
        .map((s) {
          try {
            final percentage = calculatePerformancePercent(s);
            return double.tryParse(percentage) ?? 0.0;
          } catch (e) {
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
                child: _summaryItem(
                  LocaleKeys.best.tr(),
                  '${bestScore.toStringAsFixed(0)}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryItem(
                  LocaleKeys.worst.tr(),
                  '${worstScore.toStringAsFixed(0)}%',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryItem(
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

  Widget _summaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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

  Widget _buildInspectorCard(BranchModel branch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: commonDeco.copyWith(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.assignedInspector.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (branch.assignedInspector == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(LocaleKeys.unassigned.tr()),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(branch.assignedInspector!.name)),
                  // We intentionally do not show route operations on branch side
                  Text(
                    branch.stop != null ? LocaleKeys.branchInRoute.tr() : '',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(int days) {
    if (days == 0) return Colors.green;
    if (days <= 7) return Colors.lightGreen;
    if (days <= 30) return Colors.orange;
    return Colors.red;
  }
}
