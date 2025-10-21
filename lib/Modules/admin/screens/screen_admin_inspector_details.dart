import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/lib/translations/locale_keys.g.dart';
import '../../../models/inspector_history_model.dart';
import '../../../models/user_model.dart';
import '../../inspector/widgets/custom_app_bar.dart';

class ScreenInspectorDetails extends StatefulWidget {
  final UserModel inspector;

  const ScreenInspectorDetails({super.key, required this.inspector});

  @override
  State<ScreenInspectorDetails> createState() => _ScreenInspectorDetailsState();
}

class _ScreenInspectorDetailsState extends State<ScreenInspectorDetails> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderAdminUsers>().getInspectorStatistics(
        widget.inspector.id,
      );
    });
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
            if (provider.inspectorStats == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.white38),
                    const SizedBox(height: 16),
                    Text(
                      'No statistics available',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // Success State
            final stats = provider.inspectorStats!;
            return RefreshIndicator(
              onRefresh: () async {
                await provider.getInspectorStatistics(widget.inspector.id);
              },
              color: AppColors.primaryRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(),
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

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryRed,
            AppColors.primaryRed.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              widget.inspector.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.inspector.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.inspector.role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (widget.inspector.region != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.inspector.region!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
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
                  label: LocaleKeys.total_inspections.tr(),
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
                  label: "Branches",
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
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          _buildScoresChart(stats),
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

  Widget _buildScoresChart(InspectorHistoryModel stats) {
    if (stats.recentScores.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get max score for scaling
    final maxScore = 10.0;
    final scores = stats.recentScores.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            const Text(
              "Recent Performance",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(scores.length, (index) {
                    final score = scores[index];
                    final height = (score / maxScore);
                    final color = _getScoreColor(score);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Score value on top
                            Text(
                              score.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Bar
                            Container(
                              height: height * 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    color.withValues(alpha: 0.8),
                                    color.withValues(alpha: 0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              // X-axis labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(scores.length, (index) {
                  return Expanded(
                    child: Text(
                      '${scores.length - index}',
                      style: TextStyle(color: Colors.white38, fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Last ${scores.length} inspections',
            style: TextStyle(color: Colors.white38, fontSize: 11),
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
