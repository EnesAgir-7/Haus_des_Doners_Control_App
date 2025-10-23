import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/inspector_history_model.dart';
import '../../../models/route_model.dart';
import '../../inspector/widgets/app_button.dart';

class AdminStopInfoSheet extends StatelessWidget {
  final RouteStopModel stop;

  const AdminStopInfoSheet({super.key, required this.stop});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStopStatusInfo();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, statusInfo),
              const SizedBox(height: 20),
              _buildInfoSection(),
              const SizedBox(height: 16),
              Center(
                child: AppButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  borderRadius: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _StopStatusInfo statusInfo) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: statusInfo.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: statusInfo.color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.store, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.branchName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusInfo.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusInfo.icon, size: 14, color: statusInfo.color),
                    const SizedBox(width: 6),
                    Text(
                      statusInfo.label,
                      style: TextStyle(
                        color: statusInfo.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Branch Name', stop.branchName),
        _infoRow('Branch Name', stop.branchName),
        _infoRow('Branch Address', stop.branchAddress ?? 'N/A'),
        _infoRow('Time Slot', formatTimeSlot(stop.timeSlot)),
        _infoRow('Status', stop.status),
        if (stop.inspectionScore != null)
          _infoRow('Inspection Score', stop.inspectionScore!),
        if (stop.createdAt != null)
          _infoRow(
            'Created At',
            DateFormat("MMMM d, yyyy 'at' h:mm a").format(stop.createdAt!),
          ),
        if (stop.completedAt != null)
          _infoRow(
            'Completed At',
            DateFormat("MMMM d, yyyy 'at' h:mm a").format(stop.completedAt!),
          ),
        if (stop.expiryDate != null)
          _infoRow(
            'Expiry Date',
            DateFormat(
              "MMMM d, yyyy 'at' h:mm a",
            ).format(stop.expiryDate!.toDate()),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHODS ---

  String formatTimeSlot(String timeSlot) {
    try {
      final date = _parseTimeSlot(timeSlot);
      return date != null ? DateFormat("MMMM d, yyyy").format(date) : timeSlot;
    } catch (e) {
      return timeSlot;
    }
  }

  _StopStatusInfo _getStopStatusInfo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDate = _parseTimeSlot(stop.timeSlot);

    if (stop.isExpired) {
      return _StopStatusInfo(
        label: "Expired",
        icon: Icons.warning_amber_rounded,
        color: Colors.deepOrange,
        gradientColors: [Colors.deepOrange, Colors.red],
      );
    }
    if (stop.isCompleted) {
      return _StopStatusInfo(
        label: "Completed",
        icon: Icons.check_circle,
        color: Colors.green,
        gradientColors: [Colors.green, const Color(0xFF2E7D32)],
      );
    }

    final isToday =
        scheduledDate != null && scheduledDate.isAtSameMomentAs(today);
    final isOverdue = scheduledDate != null && scheduledDate.isBefore(today);

    if (isOverdue) {
      return _StopStatusInfo(
        label: "Overdue",
        icon: Icons.error_outline,
        color: Colors.red,
        gradientColors: [Colors.red.shade700, Colors.red.shade900],
      );
    }
    if (isToday) {
      if (stop.isCurrent) {
        return _StopStatusInfo(
          label: "In Progress",
          icon: Icons.play_circle_outline,
          color: Colors.amber,
          gradientColors: [Colors.amber, Colors.orange],
        );
      }
      return _StopStatusInfo(
        label: "Today",
        icon: Icons.today,
        color: Colors.green,
        gradientColors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
      );
    }
    return _StopStatusInfo(
      label: "Scheduled",
      icon: Icons.schedule,
      color: Colors.blue,
      gradientColors: [AppColors.primaryRed, AppColors.primaryDark],
    );
  }

  DateTime? _parseTimeSlot(String timeSlot) {
    try {
      return DateTime.parse(timeSlot);
    } catch (e) {
      return null;
    }
  }
}



class ParsedScore {
  final double score;
  final double maxScore;

  ParsedScore({required this.score, required this.maxScore});
}

class _StopStatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  _StopStatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });
}

Widget buildScoresChart(InspectorHistoryModel stats) {
  if (stats.recentScores.isEmpty) {
    return const SizedBox.shrink();
  }

  final parsedScores = <ParsedScore>[];
  double globalMaxScore = 0;

  for (final scoreStr in stats.recentScores.take(10)) {
    try {
      final parts = scoreStr.split('/');
      if (parts.length == 2) {
        final score = double.parse(parts[0].trim());
        final maxScore = double.parse(parts[1].trim());
        parsedScores.add(ParsedScore(score: score, maxScore: maxScore));

        if (maxScore > globalMaxScore) {
          globalMaxScore = maxScore;
        }
      }
    } catch (e) {
      print('Error parsing score: $scoreStr');
    }
  }

  if (parsedScores.isEmpty) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.show_chart, color: AppColors.primaryRed, size: 20),
          const SizedBox(width: 8),
          Text(
            "Recent Performance",
            style: TextStyle(
              color: AppColors.primaryRed,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Excellent (0-3)'),
                const SizedBox(width: 12),
                _buildLegendItem(AppColors.amber, 'Good (4-6)'),
                const SizedBox(width: 12),
                _buildLegendItem(AppColors.primaryRed, 'Poor (7+)'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(parsedScores.length, (index) {
                  final parsedScore = parsedScores[index];
                  final score = parsedScore.score;
                  final maxScore = parsedScore.maxScore;

                  final invertedScore = globalMaxScore - score;
                  final heightRatio = (invertedScore / globalMaxScore).clamp(
                    0.05,
                    1.0,
                  );
                  final barHeight = heightRatio * 120;

                  final color = _getScoreColorReversed(score);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.5),
                              ),
                            ),
                            child: FittedBox(
                              child: Text(
                                '${score.toInt()}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [color, color.withValues(alpha: 0.6)],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '/${maxScore.toInt()}',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(parsedScores.length, (index) {
                return Expanded(
                  child: Text(
                    '#${parsedScores.length - index}',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
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
          'Last ${parsedScores.length} inspection${parsedScores.length > 1 ? 's' : ''}',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ],
  );
}
Widget _buildLegendItem(Color color, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: Colors.white54, fontSize: 10)),
    ],
  );
}

// Reversed color logic: Lower score = Better (Green)
Color _getScoreColorReversed(double score) {
  if (score <= 3) return Colors.green; // Excellent
  if (score <= 6) return AppColors.amber; // Good
  return AppColors.primaryRed; // Poor
}
