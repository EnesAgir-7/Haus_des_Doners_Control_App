import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:provider/provider.dart';

import '../../../common_services/remote_config_service.dart';
import '../../../common_services/send_notification_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/inspector_history_model.dart';
import '../../../models/user_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../widgets/performance_chart.dart';
import 'screen_admin_inspector_branches.dart';
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

  List<String> _generateLast12Months() {
    final List<String> months = [];
    final now = DateTime.now();

    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = '${date.month.toString().padLeft(2, '0')}-${date.year}';
      months.add(monthKey);
    }

    return months;
  }

  String _getMonthNameFromKey(String monthKey) {
    // monthKey format: "01-2025"
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;

    final month = parts[0];

    var monthNames = {
      "01": LocaleKeys.january.tr(),
      "02": LocaleKeys.february.tr(),
      "03": LocaleKeys.march.tr(),
      "04": LocaleKeys.april.tr(),
      "05": LocaleKeys.may.tr(),
      "06": LocaleKeys.june.tr(),
      "07": LocaleKeys.july.tr(),
      "08": LocaleKeys.august.tr(),
      "09": LocaleKeys.september.tr(),
      "10": LocaleKeys.october.tr(),
      "11": LocaleKeys.november.tr(),
      "12": LocaleKeys.december.tr(),
    };

    return monthNames[month] ?? month;
  }

  int _getYearFromKey(String monthKey) {
    final parts = monthKey.split('-');
    return parts.length == 2 ? int.parse(parts[1]) : DateTime.now().year;
  }

  int _getMonthFromKey(String monthKey) {
    final parts = monthKey.split('-');
    return parts.length == 2 ? int.parse(parts[0]) : DateTime.now().month;
  }

  void _switchToMonthKey(String monthKey) {
    final year = _getYearFromKey(monthKey);
    final month = _getMonthFromKey(monthKey);
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Consumer<ProviderAdminUsers>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryRed),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.loadingStatistics.tr(),
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.errorLoadingStatistics.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.white38),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.noStatisticsAvailable.tr(),
                    style: TextStyle(color: Colors.white70, fontSize: 16),
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
                  SizedBox(height: 16),
                  _buildMonthSelector(provider),
                  SizedBox(height: 10),

                  // Show stats if available, otherwise show no data message
                  if (provider.currentMonthStats != null) ...[
                    _buildStatsGrid(provider.currentMonthStats!),
                    _buildDetailedSection(provider.currentMonthStats!),
                  ] else ...[
                    SizedBox(height: 100),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LocaleKeys.noDataForSelectedMonth.tr(),
                            style: TextStyle(
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
    // Generate last 12 months
    final last12Months = _generateLast12Months();

    // Filter to show only available months (optional)
    final availableMonths = provider.inspectorAllData?.availableMonths ?? [];

    // Use last12Months for dropdown, but mark unavailable ones
    if (_selectedMonthKey == null && last12Months.isNotEmpty) {
      _selectedMonthKey = last12Months.first; // Current month
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonthKey,
          isExpanded: true,
          isDense: false,
          dropdownColor: Color(0xFF1a1a1a),
          icon: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.primaryRed,
              size: 24,
            ),
          ),
          style: TextStyle(
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
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primaryRed,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '${_getMonthNameFromKey(monthKey)} ${_getYearFromKey(monthKey)}',
                    style: TextStyle(
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
            final monthName = _getMonthNameFromKey(monthKey);
            final year = _getYearFromKey(monthKey);

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
                    SizedBox(width: 12),
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
                                SizedBox(width: 6),
                                Text(
                                  LocaleKeys.noData.tr(),
                                  style: TextStyle(
                                    color: Colors.white30,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2),
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
                      Icon(
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  label: LocaleKeys.branchesVisitedReported.tr(),
                  value: stats.totalInspections.toString(),
                  icon: Icons.assignment_turned_in_outlined,
                  gradientColors: [Color(0xFF4A5568), Color(0xFF2D3748)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatCard(
                  label: LocaleKeys.assignedVehicles.tr(),
                  value: stats.vehicleIds.length.toString(),
                  icon: Icons.star_outline,
                  gradientColors: [Color(0xFF0F766E), Color(0xFF115E59)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  label: LocaleKeys.tasksCompleted.tr(),
                  value: "${stats.tasksCompleted}/${stats.tasksTotal}",
                  icon: Icons.check_circle_outline,
                  gradientColors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  subtitle: "$completionRate%",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatCard(
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScreenAdminInspectorBranches(
                          inspectorName: widget.inspector.name,
                          branchIds: stats.branchesIds,
                        ),
                      ),
                    );
                  },
                  label: LocaleKeys.branchesAssigned.tr(),
                  value: stats.branchesIds.length.toString(),
                  icon: Icons.store_outlined,
                  gradientColors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    String? subtitle,
    VoidCallback? ontap,
  }) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    "(${subtitle})",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
        Icon(Icons.update, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          '${LocaleKeys.lastUpdated.tr()} ',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          _formatDate(stats.lastUpdated),
          style: TextStyle(
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
