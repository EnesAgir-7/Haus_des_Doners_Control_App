import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';

Widget buildBranchPerformanceChart(List<String>? last12MonthsScores) {
  // Parse scores and extract actual values
  final List<Map<String, dynamic>> parsedScores = [];
  double maxActualScore = 0;

  for (var s in last12MonthsScores!) {
    if (s.contains('/')) {
      final parts = s.split('/');
      final score = double.tryParse(parts.first.trim()) ?? 0.0;
      final max = double.tryParse(parts.last.trim()) ?? 100.0;
      final percentage = (max > 0) ? (score / max) * 100 : 0.0;

      parsedScores.add({
        'score': score,
        'maxScore': max,
        'percentage': percentage,
        'displayText': s,
      });

      if (score > maxActualScore) maxActualScore = score;
    } else {
      final score = double.tryParse(s) ?? 0.0;
      parsedScores.add({
        'score': score,
        'maxScore': 100.0,
        'percentage': score,
        'displayText': score.toStringAsFixed(0),
      });

      if (score > maxActualScore) maxActualScore = score;
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.bar_chart, color: AppColors.primaryRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocaleKeys.last12Inspections.tr(),
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: commonDeco,
        child: Column(
          children: [
            // Max score indicator
            if (maxActualScore > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.oldestToLatest.tr(),
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      LocaleKeys.scale.tr().replaceAll(
                        '{maxScore}',
                        maxActualScore.toStringAsFixed(0),
                      ),
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            // Chart with SingleChildScrollView to prevent overflow
            SizedBox(
              height: 240,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: NeverScrollableScrollPhysics(),
                child: SizedBox(
                  height: 240,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(parsedScores.length, (index) {
                      final item = parsedScores[index];
                      final score = item['score'] as double;
                      final maxScore = item['maxScore'] as double;
                      final percentage = item['percentage'] as double;

                      final invertedPercentage = 100 - percentage;
                      final height = (invertedPercentage / 100) * 160;

                      // Color based on percentage (lower score = green)
                      final color = getBranchPerformanceColor(
                        invertedPercentage,
                      );

                      // Calculate month number (1 = oldest, 12 = latest)
                      final monthNumber = index + 1;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Score label
                              if (score > 0)
                                Container(
                                  height: 32,
                                  alignment: Alignment.bottomCenter,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        score.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                      ),
                                      if (maxScore != 100)
                                        Text(
                                          '/${maxScore.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 7,
                                          ),
                                          maxLines: 1,
                                        ),
                                    ],
                                  ),
                                )
                              else
                                SizedBox(height: 32),

                              const SizedBox(height: 4),

                              // Bar
                              Container(
                                height: height.clamp(4.0, 160.0).toDouble(),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      color,
                                      color.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Month number label
                              Container(
                                height: 20,
                                alignment: Alignment.topCenter,
                                child: Text(
                                  monthNumber.toString(),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend with wrapped layout
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem(Colors.green, LocaleKeys.excellent.tr()),
                _buildLegendItem(Colors.lightGreen, LocaleKeys.good.tr()),
                _buildLegendItem(Colors.orange, LocaleKeys.average.tr()),
                _buildLegendItem(Colors.red, LocaleKeys.poor.tr()),
              ],
            ),
          ],
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
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(color: Colors.white54, fontSize: 10),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

Color getBranchPerformanceColor(double percentage) {
  if (percentage >= 80) return Colors.green;
  if (percentage >= 60) return Colors.lightGreen;
  if (percentage >= 40) return Colors.orange;
  return Colors.red;
}
