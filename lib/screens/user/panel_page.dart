import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/providers/provider_branches.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums.dart';
import '../../providers/provider_panel.dart';
import '../../providers/provider_route.dart';
import '../../providers/provider_tasks.dart';
import '../../translations/locale_keys.g.dart';
import '../../widgets/statistic_card.dart';

class PanelPage extends StatefulWidget {
  const PanelPage({super.key});

  @override
  State<PanelPage> createState() => _PanelPageState();
}

class _PanelPageState extends State<PanelPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderPanel>().initialize();
      context.read<ProviderRoute>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ProviderPanel>().refresh();
          await context.read<ProviderRoute>().refresh();
        },
        color: AppColors.primaryRed,
        backgroundColor: AppColors.lightBlack,
        child: Consumer<ProviderPanel>(
          builder: (context, panelProvider, child) {
            if (panelProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            }

            if (panelProvider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: AppColors.primaryRed,
                    ),
                    SizedBox(height: 16),
                    Text(
                      LocaleKeys.error_occurred.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        panelProvider.errorMessage!,
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => panelProvider.refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                      ),
                      child: Text(LocaleKeys.try_again.tr()),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardCard(provider: panelProvider),
                  const SizedBox(height: 16),
                  const DailySummarySection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final ProviderPanel provider;

  const DashboardCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Row(
            children: [
              const Icon(Icons.search, color: Colors.lightBlueAccent, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loggedInUser?.name ?? LocaleKeys.controller_name.tr(),
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loggedInUser?.region ?? LocaleKeys.region.tr(),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              // Time Range Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightRed,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryRed.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButton<TimeRange>(
                  value: provider.selectedRange,
                  isDense: true,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.lightBlack,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primaryRed,
                    size: 18,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [TimeRange.daily, TimeRange.weekly, TimeRange.monthly]
                      .map((time) {
                        return DropdownMenuItem(
                          value: time,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.today,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(time.name),
                            ],
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (range) {
                    if (range != null) {
                      provider.changeTimeRange(range);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (provider.isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                Consumer<ProviderBranches>(
                  builder: (context, brachCont, child) {
                    return StatBox(
                      isLoading: brachCont.isLoading,
                      number: brachCont.branchCount.toString(),
                      label: "Assigned Branches",
                      icon: Icons.apartment,
                      color: Colors.blue,
                    );
                  },
                ),
                StatBox(
                  number: provider.completedInspections.toString(),
                  label: _getRangeLabel(provider.selectedRange, context),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                Consumer<ProviderTasks>(
                  builder: (context, taskPro, child) {
                    return StatBox(
                      isLoading: taskPro.isLoading,
                      number: taskPro.tasks.length.toString(),
                      label: LocaleKeys.pending_task.tr(),
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    );
                  },
                ),
                StatBox(
                  number: provider.averageScore.toStringAsFixed(1),
                  label: LocaleKeys.average_score.tr(),
                  icon: Icons.star,
                  color: AppColors.amber,
                ),
              ],
            ),

          const SizedBox(height: 16),
          Consumer<ProviderRoute>(
            builder: (context, ro, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getProgressLabel(provider.selectedRange, context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(provider.calculateCompletionPercentage(ro.completedStops, ro.totalStops) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: provider.calculateCompletionPercentage(
                          ro.completedStops,
                          ro.totalStops,
                        ),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryRed,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${ro.completedStops} / ${ro.totalStops} ${LocaleKeys.branches_checked.tr()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getRangeLabel(TimeRange range, BuildContext context) {
    switch (range) {
      case TimeRange.daily:
        return "Today Checks";
      case TimeRange.weekly:
        return LocaleKeys.this_week_check.tr();
      case TimeRange.monthly:
        return "This month";
    }
  }

  String _getProgressLabel(TimeRange range, BuildContext context) {
    switch (range) {
      case TimeRange.daily:
        return "Daily Progress";
      case TimeRange.weekly:
        return "Weekly Progress";
      case TimeRange.monthly:
        return LocaleKeys.monthly_progress.tr();
    }
  }
}

class StatBox extends StatelessWidget {
  final String number;
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isLoading;

  const StatBox({
    super.key,
    required this.number,
    required this.label,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? AppColors.primaryRed).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color ?? AppColors.primaryRed),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: isLoading
                    ? CircularProgressIndicator(
                        color: color ?? AppColors.primaryRed,
                      )
                    : Text(
                        number,
                        style: TextStyle(
                          color: color ?? AppColors.primaryRed,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class DailySummarySection extends StatelessWidget {
  const DailySummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderRoute>(
      builder: (context, routeProvider, child) {
        if (routeProvider.isLoading) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          );
        }

        final stops = routeProvider.todaysStops;
        // final stops = routeProvider.stops;

        if (stops.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insert_chart),
                  const SizedBox(width: 6),
                  Text(
                    LocaleKeys.your_route_plan.tr(),
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 40,
                        color: Colors.white38,
                      ),
                      SizedBox(height: 8),
                      Text(
                        LocaleKeys.no_route_today.tr(),
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_outlined, color: Colors.lightBlueAccent),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.daily_summary.tr(),
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${routeProvider.completedStops}/${routeProvider.totalStops}',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              spacing: 16,
              children: stops.take(5).map((stop) {
                return StatisticCard(stop: stop);
              }).toList(),
            ),

            if (stops.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.route,
                    size: 16,
                    color: AppColors.primaryRed,
                  ),
                  label: Text(
                    "${LocaleKeys.view_all_route.tr()} (${stops.length} ${LocaleKeys.stops.tr()})",
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// class PanelPage extends StatelessWidget {
//   const PanelPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: const [
//             DashboardCard(),
//             SizedBox(height: 16),
//             DailySummarySection(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class DashboardCard extends StatelessWidget {
//   const DashboardCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.lightBlack,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.primaryRed),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.search, color: Colors.lightBlueAccent, size: 20),
//               const SizedBox(width: 6),
//               Text(
//                 LocaleKeys.controller_name.tr(),
//                 style: const TextStyle(
//                   color: AppColors.primaryRed,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             LocaleKeys.region.tr(),
//             style: const TextStyle(color: Colors.white70, fontSize: 14),
//           ),
//           const SizedBox(height: 16),

//           GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 2,
//             crossAxisSpacing: 12,
//             mainAxisSpacing: 12,
//             childAspectRatio: 2.2,
//             children: [
//               StatBox(number: "40", label: LocaleKeys.total_branch.tr()),
//               StatBox(number: "12", label: LocaleKeys.this_week_check.tr()),
//               StatBox(number: "3", label: LocaleKeys.pending_task.tr()),
//               StatBox(number: "8.5", label: LocaleKeys.average_score.tr()),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class StatBox extends StatelessWidget {
//   final String number;
//   final String label;

//   const StatBox({super.key, required this.number, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.lightRed,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//       child: Column(
//         children: [
//           Text(
//             number,
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: AppColors.primaryRed,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 13, color: Colors.white70),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class DailySummarySection extends StatelessWidget {
//   const DailySummarySection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Icon(Icons.insert_chart, color: Colors.purpleAccent),
//             const SizedBox(width: 6),
//             Text(
//               LocaleKeys.daily_summary.tr(),
//               style: const TextStyle(
//                 color: AppColors.primaryRed,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         StatisticCard(
//           time: "09:30",
//           title: LocaleKeys.haus_beyoglu.tr(),
//           status: LocaleKeys.completed.tr(),
//           statusColor: Colors.green,
//           subtitle: LocaleKeys.score_92.tr(),
//           icon: Icons.check_box,
//         ),
//         const SizedBox(height: 10),
//         StatisticCard(
//           time: "14:00",
//           title: LocaleKeys.haus_sisli.tr(),
//           status: LocaleKeys.waiting.tr(),
//           statusColor: Colors.amber,
//           subtitle: "",
//           icon: Icons.hourglass_bottom,
//         ),
//       ],
//     );
//   }
// }
