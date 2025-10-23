import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/lib/translations/locale_keys.g.dart';
import '../../../models/inspector_history_model.dart';
import '../../../models/user_model.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../widgets/widgets_admin_branch_details.dart';

class ScreenInspectorDetails extends StatefulWidget {
  final UserModel inspector;

  const ScreenInspectorDetails({super.key, required this.inspector});

  @override
  State<ScreenInspectorDetails> createState() => _ScreenInspectorDetailsState();
}

class _ScreenInspectorDetailsState extends State<ScreenInspectorDetails> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderAdminUsers>().getInspectorStatistics(
        widget.inspector.id,
      );
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _changeMonth(int delta) {
    setState(() {
      selectedMonth += delta;
      if (selectedMonth > 12) {
        selectedMonth = 1;
        selectedYear++;
      } else if (selectedMonth < 1) {
        selectedMonth = 12;
        selectedYear--;
      }
    });

    // Switch month without API call
    context.read<ProviderAdminUsers>().switchMonth(selectedYear, selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: "${widget.inspector.name}'s Statistics"),
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
        child: Consumer<ProviderAdminUsers>(
          builder: (context, provider, child) {
            // Loading State
            if (provider.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryRed),
                    const SizedBox(height: 16),
                    Text(
                      'Loading statistics...',
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
                        'Error Loading Statistics',
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
                        label: const Text('Retry'),
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
            if (provider.currentMonthStats == null) {
              return Column(
                children: [
                  // _buildProfileHeader(),
                  SizedBox(height: 16),
                  _buildMonthSelector(provider),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No statistics available for\n${_getMonthName(selectedMonth)} $selectedYear',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Success State
            final stats = provider.currentMonthStats!;
            return RefreshIndicator(
              onRefresh: () async {
                await provider.getInspectorStatistics(widget.inspector.id);
              },
              color: AppColors.primaryRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // _buildProfileHeader(),
                    SizedBox(height: 16),
                    _buildMonthSelector(provider),
                    SizedBox(height: 10),
                    _buildStatsGrid(stats),
                    _buildDetailedSection(stats),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelector(ProviderAdminUsers provider) {
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth == now.month && selectedYear == now.year;

    // Check if selected month has data
    final hasData =
        provider.inspectorAllData?.getMonth(selectedYear, selectedMonth) !=
        null;

    bool canGoBack =
        selectedYear > now.year - 1 ||
        (selectedYear == now.year - 1 && selectedMonth > now.month);

    // Determine if we can go forward (not beyond current month)
    bool canGoForward =
        !(selectedYear == now.year && selectedMonth == now.month);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8), // Reduced bottom margin
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8), // Slightly smaller radius
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: canGoBack ? () => _changeMonth(-1) : null,
            icon: Icon(Icons.chevron_left, color: Colors.white70, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              minimumSize: Size.zero, // Shrink button size
              padding: EdgeInsets.all(6), // Reduced padding
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Important for shrinking
              children: [
                // Combined Month and Year on one line
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _getMonthName(selectedMonth),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16, // Reduced size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' ${selectedYear.toString()}', // Space added for separation
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14, // Reduced size
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4), // Small separator
                // Status Tags Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCurrentMonth) ...[
                      // Current Tag
                      _StatusTag(
                        text: 'Current',
                        color: AppColors.primaryRed,
                        backgroundColor: AppColors.green,
                        fontSize: 9,
                      ),
                      const SizedBox(width: 4), // Reduced spacing
                    ],
                    // Data Status Tag
                    _StatusTag(
                      text: hasData ? 'Data Available' : 'No Data',
                      icon: hasData ? Icons.check_circle : Icons.info_outline,
                      color: hasData ? Colors.green : Colors.grey,
                      backgroundColor: hasData
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      fontSize: 9,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canGoForward ? () => _changeMonth(1) : null,
            icon: Icon(Icons.chevron_right, color: Colors.white70, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              minimumSize: Size.zero, // Shrink button size
              padding: EdgeInsets.all(6), // Reduced padding
            ),
          ),
        ],
      ),
    );
  }

  // You'll need this helper widget (_StatusTag) if you want to use the streamlined approach above

  Widget _StatusTag({
    required String text,
    IconData? icon,
    required Color color,
    required Color backgroundColor,
    required double fontSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 1, // Reduced vertical padding
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: color),
            const SizedBox(width: 3), // Reduced spacing
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                  label: "Branches Visited & Reported",
                  value: stats.totalInspections.toString(),
                  icon: Icons.assignment_turned_in_outlined,
                  gradientColors: [Color(0xFF4A5568), Color(0xFF2D3748)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatCard(
                  label: LocaleKeys.average_score.tr(),
                  value: stats.avgScore.toStringAsFixed(1),
                  icon: Icons.star_outline,
                  gradientColors: [
                    _getScoreColor(stats.avgScore),
                    _getScoreColor(stats.avgScore).withValues(alpha: 0.7),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  label: "Tasks Completed",
                  value: "${stats.tasksCompleted}/${stats.tasksTotal}",
                  icon: Icons.check_circle_outline,
                  gradientColors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  subtitle: "$completionRate%",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatCard(
                  label: "Branches Assigned",
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
          _buildInfoRow(
            "Vehicles Assigned",
            stats.vehicleIds.length.toString(),
            Icons.directions_car_outlined,
          ),
          const Divider(height: 24, color: Colors.white12),
          buildScoresChart(stats),
          const Divider(height: 24, color: Colors.white12),
          _buildLastUpdatedRow(stats),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdatedRow(InspectorHistoryModel stats) {
    return Row(
      children: [
        Icon(Icons.update, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          'Last updated: ',
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

  Color _getScoreColor(double score) {
    if (score >= 7.0) return Colors.green;
    if (score >= 4.0) return Colors.amber;
    return AppColors.primaryRed;
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }
}

// Helper class to store parsed scores
