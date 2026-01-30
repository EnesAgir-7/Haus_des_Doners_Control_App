import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:provider/provider.dart';

import '../../../common_services/remote_config_service.dart';
import '../../../common_services/send_notification_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../helpers/app_helpers.dart';
import '../../../models/inspector_history_model.dart';
import '../../../models/user_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../common/widgets/compact_stat_card.dart';
import '../../common/widgets/inspector_details_bottomsheets.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../widgets/performance_chart.dart';
import 'screen_admin_user_details.dart';

class ScreenInspectorDetails extends StatefulWidget {
  final UserModel inspector;

  const ScreenInspectorDetails({super.key, required this.inspector});

  @override
  State<ScreenInspectorDetails> createState() => _ScreenInspectorDetailsState();
}

class _ScreenInspectorDetailsState extends State<ScreenInspectorDetails> {
  String? _selectedMonthKey;

  final remoteConfig = RemoteConfigService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ProviderAdminUsers>();
      await provider.getInspectorStatistics(widget.inspector.id);

      // Set current month as default
      if (mounted) {
        final now = DateTime.now();
        final currentMonthKey =
            '${now.month.toString().padLeft(2, '0')}-${now.year}';
        setState(() {
          _selectedMonthKey = currentMonthKey;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _switchToMonthKey(String monthKey) {
    final year = getYearFromKey(monthKey);
    final month = getMonthFromKey(monthKey);
    context.read<ProviderAdminUsers>().switchMonth(year, month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(
        title: "${widget.inspector.name} ${LocaleKeys.statistics.tr()}",
        actions: [
          if (remoteConfig.showInspectorNotification)
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: () {
                showNotifyDialog(
                  context: context,
                  inspectorId: widget.inspector.id,
                  inspectorName: widget.inspector.name,
                  fcmTokens: widget.inspector.fcmTokens,
                );
              },
            ),
          IconButton.filled(
            visualDensity: VisualDensity.comfortable,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ScreenAdminUserDetails(user: widget.inspector),
                ),
              );
            },
            icon: Text(
              widget.inspector.name[0],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Consumer<ProviderAdminUsers>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryRed),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.loadingStatistics.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Error State
          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.errorLoadingStatistics.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.getInspectorStatistics(widget.inspector.id);
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(LocaleKeys.retry.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // No Data State
          if (provider.inspectorAllData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.noStatisticsAvailable.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Success State - Show month selector always
          return RefreshIndicator(
            onRefresh: () async {
              await provider.getInspectorStatistics(widget.inspector.id);
            },
            color: AppColors.primaryRed,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildMonthSelector(provider),
                  const SizedBox(height: 10),

                  // Show stats if available, otherwise show no data message
                  if (provider.currentMonthStats != null) ...[
                    _buildStatsGrid(provider.currentMonthStats!),
                    _buildDetailedSection(provider.currentMonthStats!),
                  ] else ...[
                    const SizedBox(height: 100),
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LocaleKeys.noDataForSelectedMonth.tr(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(ProviderAdminUsers provider) {
    final last12Months = generateLast12Months();

    final availableMonths = provider.inspectorAllData?.availableMonths ?? [];

    if (_selectedMonthKey == null && last12Months.isNotEmpty) {
      _selectedMonthKey = last12Months.first; // Current month
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryRed.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonthKey,
          isExpanded: true,
          isDense: false,
          dropdownColor: const Color(0xFF1a1a1a),
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.primaryRed,
              size: 24,
            ),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          selectedItemBuilder: (BuildContext context) {
            return last12Months.map((monthKey) {
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primaryRed,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${getMonthNameFromKey(monthKey)} ${getYearFromKey(monthKey)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: last12Months.map((monthKey) {
            final isSelected = monthKey == _selectedMonthKey;
            final isAvailable = availableMonths.contains(monthKey);
            final monthName = getMonthNameFromKey(monthKey);
            final year = getYearFromKey(monthKey);

            return DropdownMenuItem<String>(
              value: monthKey,
              child: Container(
                child: Row(
                  children: [
                    Icon(
                      isAvailable
                          ? Icons.calendar_today_rounded
                          : Icons.calendar_today_outlined,
                      color: isSelected
                          ? AppColors.primaryRed
                          : (isAvailable ? Colors.white60 : Colors.white30),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                monthName,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isAvailable
                                            ? Colors.white70
                                            : Colors.white38),
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              if (!isAvailable) ...[
                                const SizedBox(width: 6),
                                Text(
                                  LocaleKeys.noData.tr(),
                                  style: const TextStyle(
                                    color: Colors.white30,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            year.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryRed.withValues(alpha: 0.8)
                                  : Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primaryRed,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newMonthKey) {
            if (newMonthKey != null) {
              setState(() {
                _selectedMonthKey = newMonthKey;
              });
              _switchToMonthKey(newMonthKey);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatsGrid(InspectorHistoryModel stats) {
    final completionRate = stats.tasksTotal > 0
        ? (stats.tasksCompleted / stats.tasksTotal * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CompactStatCard(
                  onTap: () {
                    // Show Inspections Bottom Sheet
                    InspectorDetailsBottomSheets.showInspectionsSheet(
                      context,
                      inspectorId: widget.inspector.id,
                      inspectorName: widget.inspector.name,
                      year: getYearFromKey(_selectedMonthKey!),
                      month: getMonthFromKey(_selectedMonthKey!),
                      totalInspections: stats.totalInspections,
                    );
                  },
                  label: LocaleKeys.branchesVisitedReported.tr(),
                  value: stats.totalInspections.toString(),
                  icon: Icons.assignment_turned_in_outlined,
                  gradientColors: [
                    const Color(0xFF4A5568),
                    const Color(0xFF2D3748),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CompactStatCard(
                  onTap: () {
                    // Show Tasks Bottom Sheet
                    InspectorDetailsBottomSheets.showTasksSheet(
                      context,
                      inspectorId: widget.inspector.id,
                      inspectorName: widget.inspector.name,
                      year: getYearFromKey(_selectedMonthKey!),
                      month: getMonthFromKey(_selectedMonthKey!),
                      totalTasks: stats.tasksTotal,
                      completedTasks: stats.tasksCompleted,
                    );
                  },
                  label: LocaleKeys.tasksCompleted.tr(),
                  value: "${stats.tasksCompleted}/${stats.tasksTotal}",
                  icon: Icons.check_circle_outline,
                  gradientColors: [
                    const Color(0xFF0F766E),
                    const Color(0xFF115E59),
                  ],
                  subtitle: "$completionRate%",
                ),
              ),
              // Expanded(
              //   child: _buildCompactStatCard(
              //     ontap: () {
              //       // Show Vehicles Bottom Sheet
              //       InspectorDetailsBottomSheets.showVehiclesSheet(
              //         context,
              //         inspectorId: widget.inspector.id,
              //         inspectorName: widget.inspector.name,
              //         year: getYearFromKey(_selectedMonthKey!),
              //         month: getMonthFromKey(_selectedMonthKey!),

              //         vehicleIds: stats.vehicleIds,
              //         totalVehicles: stats.vehicleIds.length,
              //       );
              //     },
              //     label: LocaleKeys.assignedVehicles.tr(),
              //     value: stats.vehicleIds.length.toString(),
              //     icon: Icons.star_outline,
              //     gradientColors: [const Color(0xFF0F766E), const Color(0xFF115E59)],
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              // Expanded(
              //   child: _buildCompactStatCard(
              //     ontap: () {
              //       // Show Tasks Bottom Sheet
              //       InspectorDetailsBottomSheets.showTasksSheet(
              //         context,
              //         inspectorId: widget.inspector.id,
              //         inspectorName: widget.inspector.name,
              //         year: getYearFromKey(_selectedMonthKey!),
              //         month: getMonthFromKey(_selectedMonthKey!),
              //         totalTasks: stats.tasksTotal,
              //         completedTasks: stats.tasksCompleted,
              //       );
              //     },
              //     label: LocaleKeys.tasksCompleted.tr(),
              //     value: "${stats.tasksCompleted}/${stats.tasksTotal}",
              //     icon: Icons.check_circle_outline,
              //     gradientColors: [
              //       const Color(0xFF0F766E),
              //       const Color(0xFF115E59),
              //     ],
              //     subtitle: "$completionRate%",
              //   ),
              // ),
              SizedBox(width: 12),
              // Expanded(
              //   child: _buildCompactStatCard(
              //     ontap: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => ScreenAdminInspectorBranches(
              //             inspectorName: widget.inspector.name,
              //             branchIds: stats.branchesIds,
              //           ),
              //         ),
              //       );
              //     },
              //     label: LocaleKeys.branchesAssigned.tr(),
              //     value: stats.branchesIds.length.toString(),
              //     icon: Icons.store_outlined,
              //     gradientColors: [
              //       const Color(0xFF9333EA),
              //       const Color(0xFF7E22CE),
              //     ],
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedSection(InspectorHistoryModel stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Usage for Inspector History:
          buildPerformanceChart(
            scores: stats.recentScores,
            title: LocaleKeys.recentPerformance.tr(),
            icon: Icons.show_chart,
            maxScoresToShow: 10,
            subtitle: LocaleKeys.lastInspections
                .tr()
                .replaceFirst('{count}', stats.recentScores.length.toString())
                .replaceFirst('{s}', stats.recentScores.length > 1 ? 's' : ''),
          ),

          const Divider(height: 24, color: Colors.white12),
          _buildLastUpdatedRow(stats),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedRow(InspectorHistoryModel stats) {
    return Row(
      children: [
        const Icon(Icons.update, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          '${LocaleKeys.lastUpdated.tr()} ',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          _formatDate(stats.lastUpdated),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }
}
