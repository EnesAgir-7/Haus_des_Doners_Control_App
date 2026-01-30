import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../helpers/app_helpers.dart';

/// Reusable performance chart widget
/// Can be used for both Inspector History and Branch Performance
Widget buildPerformanceChart({
  required List<String> scores,
  required String title,
  required IconData icon,
  bool removeDeco = false,
  String? subtitle,
  int? maxScoresToShow,
}) {
  final scoresToUse = maxScoresToShow != null
      ? scores.take(maxScoresToShow).toList()
      : scores;

  if (scoresToUse.isEmpty) {
    return const SizedBox.shrink();
  }

  final parsedScores = <ParsedScore>[];
  double globalMaxScore = 0;

  for (final scoreStr in scoresToUse) {
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
          Icon(icon, color: AppColors.primaryRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
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
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: removeDeco
            ? null
            : BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
        child: Column(
          children: [
            // Legend
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.green, '100%'),
                  const SizedBox(width: 12),
                  _buildLegendItem(AppColors.amber, '75%'),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.orange, '50%'),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.deepOrange, '25%'),
                  const SizedBox(width: 12),
                  _buildLegendItem(AppColors.primaryRed, '0%'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Chart with dynamic width control - Fit in single frame
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Bars
                  SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(parsedScores.length, (index) {
                        final parsedScore = parsedScores[index];
                        final percentage = calculatePerformancePercent(
                          scoresToUse[index],
                        );

                        final heightRatio = (double.tryParse(percentage)! / 100)
                            .clamp(0.05, 1.0);
                        final barHeight = heightRatio * 120;

                        final color = getPercentageColor(
                          double.tryParse(percentage)!,
                        );

                        return Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 40),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${percentage}%',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 9, // Slightly smaller
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.visible,
                                      softWrap: false,
                                    ),
                                    const SizedBox(height: 6),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: barHeight),
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      curve: Curves.easeOutQuart,
                                      builder: (context, value, child) {
                                        return Container(
                                          width: double.infinity,
                                          height: value,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                color,
                                                color.withValues(alpha: 0.9),
                                              ],
                                            ),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(4),
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${parsedScore.score.toInt()}/${parsedScore.maxScore.toInt()}',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize:
                                              8, // Smaller width resilience
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Index numbers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(parsedScores.length, (index) {
                      return Expanded(
                        child: Text(
                          '#${parsedScores.length - index}',
                          style: const TextStyle(
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
          ],
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Center(
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
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
        style: const TextStyle(color: Colors.white54, fontSize: 10),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

class ParsedScore {
  final double score;
  final double maxScore;

  ParsedScore({required this.score, required this.maxScore});
}
