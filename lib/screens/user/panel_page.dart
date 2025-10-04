import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/provider_panel.dart';
import '../../providers/provider_route.dart';
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
    final user = provider.currentUser;
    final stats = provider.currentMonthStats;

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
          Row(
            children: [
              const Icon(Icons.search, color: Colors.lightBlueAccent, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  user?.name ?? LocaleKeys.controller_name.tr(),
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
          Text(
            user?.region ?? LocaleKeys.region.tr(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              StatBox(
                number: provider.totalBranches.toString(),
                label: LocaleKeys.total_branch.tr(),
              ),
              StatBox(
                number: provider.completedInspections.toString(),
                label: LocaleKeys.this_week_check.tr(),
              ),
              StatBox(
                number: provider.pendingInspections.toString(),
                label: LocaleKeys.pending_task.tr(),
              ),
              StatBox(
                number: provider.averageScore.toStringAsFixed(1),
                label: LocaleKeys.average_score.tr(),
              ),
            ],
          ),

          if (stats != null) ...[
            const SizedBox(height: 16),
            Container(
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
                        LocaleKeys.monthly_progress.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${provider.progressPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
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
                      value: provider.progressPercent / 100,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryRed,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.completedInspections} / ${provider.totalBranches} ${LocaleKeys.branches_checked.tr()}',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String number;
  final String label;

  const StatBox({super.key, required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center,
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

        final todaysRoute = routeProvider.todaysRoute;
        final stops = routeProvider.stops;

        if (todaysRoute == null || stops.isEmpty) {
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
                const Icon(Icons.insert_chart, color: Colors.purpleAccent),
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

            ...stops.take(5).map((stop) {
              Color statusColor;
              String statusText;
              IconData statusIcon;

              if (stop.isCompleted) {
                statusColor = Colors.green;
                statusText = LocaleKeys.completed.tr();
                statusIcon = Icons.check_box;
              } else if (stop.isCurrent) {
                statusColor = Colors.blue;
                statusText = LocaleKeys.current_location.tr();
                statusIcon = Icons.my_location;
              } else {
                statusColor = Colors.amber;
                statusText = LocaleKeys.waiting.tr();
                statusIcon = Icons.hourglass_bottom;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: StatisticCard(
                  time: stop.timeSlot.split(' - ')[0],
                  title: stop.branchName,
                  status: statusText,
                  statusColor: statusColor,
                  subtitle: stop.isCompleted
                      ? "${LocaleKeys.score.tr()}: ${stop.inspectionId != null ? '9.0' : '-'}"
                      : "",
                  icon: statusIcon,
                ),
              );
            }).toList(),

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
