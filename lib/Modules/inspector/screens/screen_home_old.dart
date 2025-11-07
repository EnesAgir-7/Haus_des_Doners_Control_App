// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:haus_des_control/Modules/common/fadded_divider.dart';
// import 'package:haus_des_control/Modules/inspector/providers/provider_bottom_nav_bar.dart';
// import 'package:haus_des_control/Modules/inspector/providers/provider_branches.dart';
// import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
// import 'package:haus_des_control/core/console.dart';
// import 'package:haus_des_control/core/constants/firebase_constants.dart';
// import 'package:provider/provider.dart';

// import '../../../core/constants/app_colors.dart';
// import '../../../core/constants/app_constants.dart';
// import '../../../core/enums.dart';
// import '../../../models/route_model.dart';
// import '../../../translations/locale_keys.g.dart';
// import '../providers/provider_panel.dart';
// import '../providers/provider_route.dart';
// import '../providers/provider_tasks.dart';
// import 'screen_submit_report.dart';

// class ScreenHome extends StatefulWidget {
//   const ScreenHome({super.key});

//   @override
//   State<ScreenHome> createState() => _ScreenHomeState();
// }

// class _ScreenHomeState extends State<ScreenHome> with TickerProviderStateMixin {
//   late AnimationController _animController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _animController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animController,
//       curve: Curves.easeOutCubic,
//     );
//     _animController.forward();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<ProviderPanel>().initialize();
//       context.read<ProviderRoute>().initialize();
//     });
//   }

//   @override
//   void dispose() {
//     _animController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.primaryDark,
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               AppColors.primaryRed.withValues(alpha: 0.08),
//               AppColors.primaryDark,
//               AppColors.primaryDark,
//             ],
//             stops: const [0.0, 0.25, 1.0],
//           ),
//         ),
//         child: RefreshIndicator(
//           onRefresh: () async {
//             await context.read<ProviderPanel>().refresh();
//             await context.read<ProviderRoute>().refresh();
//           },
//           color: AppColors.primaryRed,
//           backgroundColor: AppColors.lightBlack,
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: SingleChildScrollView(
//               physics: const AlwaysScrollableScrollPhysics(
//                 // parent: BouncingScrollPhysics(),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,

//                 children: [
//                   SizedBox(height: 10),
//                   // User Info Header
//                   const UserInfoHeader(),

//                   // SECTION 1: TOTAL ASSIGNMENTS (Static Overview)
//                   const OverviewSection(),
//                   FadedDivider(color: AppColors.primaryRed, height: 5),

//                   // SECTION 2: PERFORMANCE METRICS (Dynamic with Time Filter)
//                   Consumer<ProviderPanel>(
//                     builder: (context, panelProvider, child) {
//                       return PerformanceSection(provider: panelProvider);
//                     },
//                   ),

//                   FadedDivider(color: AppColors.primaryRed, height: 5),
//                   // SECTION 3: TODAY'S ROUTE PLAN (with progress)
//                   const RoutePlanSection(),
//                   SizedBox(height: 10),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // User Info Header Widget
// class UserInfoHeader extends StatelessWidget {
//   const UserInfoHeader({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppColors.lightBlack,
//             AppColors.lightBlack.withValues(alpha: 0.8),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.3),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           InkWell(
//             onTap: () {
//               console(loggedInUser!.fcmTokens?.toList());
//             },
//             child: Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     AppColors.primaryRed.withValues(alpha: 0.25),
//                     AppColors.primaryRed.withValues(alpha: 0.15),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Icon(
//                 Icons.person_outline,
//                 color: AppColors.primaryRed,
//                 size: 28,
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   loggedInUser?.name ?? LocaleKeys.controller_name.tr(),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 19,
//                     letterSpacing: -0.5,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.location_on,
//                       size: 15,
//                       color: AppColors.primaryRed.withValues(alpha: 0.7),
//                     ),
//                     const SizedBox(width: 5),
//                     Text(
//                       loggedInUser?.region ?? LocaleKeys.region.tr(),
//                       style: TextStyle(
//                         color: Colors.white.withValues(alpha: 0.6),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // SECTION 1: Overview (Static Total Assignments)
// class OverviewSection extends StatelessWidget {
//   const OverviewSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       // decoration: BoxDecoration(
//       //   gradient: LinearGradient(
//       //     begin: Alignment.topLeft,
//       //     end: Alignment.bottomRight,
//       //     colors: [
//       //       AppColors.lightBlack,
//       //       AppColors.lightBlack.withValues(alpha: 0.8),
//       //     ],
//       //   ),
//       //   borderRadius: BorderRadius.circular(24),
//       //   border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
//       //   boxShadow: [
//       //     BoxShadow(
//       //       color: Colors.black.withValues(alpha: 0.3),
//       //       blurRadius: 20,
//       //       offset: const Offset(0, 10),
//       //     ),
//       //   ],
//       // ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.blue.withValues(alpha: 0.2),
//                       Colors.blue.withValues(alpha: 0.1),
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   Icons.dashboard_outlined,
//                   color: Colors.blue,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     LocaleKeys.total_assignments.tr(),
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: -0.3,
//                     ),
//                   ),
//                   Text(
//                     LocaleKeys.overview.tr(),
//                     style: TextStyle(
//                       color: Colors.white.withValues(alpha: 0.5),
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 2,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//             childAspectRatio: 1.4,
//             children: [
//               Consumer<ProviderBranches>(
//                 builder: (context, branchCont, child) {
//                   return StatBox(
//                     isLoading: branchCont.isLoading,
//                     number: branchCont.branchCount.toString(),
//                     label: LocaleKeys.assigned_branches.tr(),
//                     icon: Icons.apartment_outlined,
//                     color: Colors.blue,
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
//                     ),
//                     onTap: () {
//                       context.read<ProviderBottomNavBar>().onItemTapped(1);
//                     },
//                   );
//                 },
//               ),
//               Consumer<ProviderTasks>(
//                 builder: (context, taskPro, child) {
//                   return StatBox(
//                     isLoading: taskPro.isLoading,
//                     number: taskPro.pendingTasksCount.toString(),
//                     label: LocaleKeys.pending_task.tr(),
//                     icon: Icons.pending_actions_outlined,
//                     color: Colors.orange,
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
//                     ),
//                     onTap: () {
//                       context.read<ProviderBottomNavBar>().onItemTapped(4);
//                     },
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // SECTION 2: Performance Metrics (Dynamic with Time Filter)
// class PerformanceSection extends StatelessWidget {
//   final ProviderPanel provider;

//   const PerformanceSection({super.key, required this.provider});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),

//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header with Time Filter
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.green.withValues(alpha: 0.2),
//                       Colors.green.withValues(alpha: 0.1),
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(Icons.trending_up, color: Colors.green, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       LocaleKeys.performance.tr(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: -0.3,
//                       ),
//                     ),
//                     Text(
//                       LocaleKeys.time_based_metrics.tr(),
//                       style: TextStyle(
//                         color: Colors.white.withValues(alpha: 0.5),
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Time Range Dropdown
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 14,
//                   vertical: 10,
//                 ),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       AppColors.primaryRed.withValues(alpha: 0.2),
//                       AppColors.primaryRed.withValues(alpha: 0.1),
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(
//                     color: AppColors.primaryRed.withValues(alpha: 0.3),
//                   ),
//                 ),
//                 child: DropdownButton<TimeRange>(
//                   value: provider.selectedRange,
//                   isDense: true,
//                   underline: const SizedBox(),
//                   dropdownColor: AppColors.lightBlack,
//                   icon: Icon(
//                     Icons.keyboard_arrow_down,
//                     color: AppColors.primaryRed,
//                     size: 20,
//                   ),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   items: [TimeRange.daily, TimeRange.weekly, TimeRange.monthly]
//                       .map((time) {
//                         return DropdownMenuItem(
//                           value: time,
//                           child: Text(time.name),
//                         );
//                       })
//                       .toList(),
//                   onChanged: (range) {
//                     if (range != null) {
//                       provider.changeTimeRange(range);
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),

//           if (provider.isLoading)
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(40),
//                 child: CircularProgressIndicator(
//                   color: AppColors.primaryRed,
//                   strokeWidth: 3,
//                 ),
//               ),
//             )
//           else
//             GridView.count(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisCount: 2,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               childAspectRatio: 1.4,
//               children: [
//                 StatBox(
//                   number: provider.completedInspections.toString(),
//                   label: _getRangeLabel(provider.selectedRange, context),
//                   icon: Icons.check_circle_outline,
//                   color: Colors.green,
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
//                   ),
//                 ),
//                 StatBox(
//                   number: provider.averageScore.toStringAsFixed(1),
//                   label: LocaleKeys.average_score.tr(),
//                   icon: Icons.star_outline,
//                   color: AppColors.amber,
//                   gradient: LinearGradient(
//                     colors: [
//                       AppColors.amber,
//                       AppColors.amber.withValues(alpha: 0.8),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   String _getRangeLabel(TimeRange range, BuildContext context) {
//     switch (range) {
//       case TimeRange.daily:
//         return LocaleKeys.today_checks.tr();
//       case TimeRange.weekly:
//         return LocaleKeys.this_week_check.tr();
//       case TimeRange.monthly:
//         return LocaleKeys.this_month.tr();
//     }
//   }
// }

// class StatBox extends StatelessWidget {
//   final String number;
//   final String label;
//   final IconData? icon;
//   final Color? color;
//   final Gradient? gradient;
//   final bool isLoading;
//   final VoidCallback? onTap;

//   const StatBox({
//     super.key,
//     required this.number,
//     required this.label,
//     this.isLoading = false,
//     this.onTap,
//     this.icon,
//     this.color,
//     this.gradient,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final boxColor = color ?? const Color(0xFFEF5350);
//     final boxGradient =
//         gradient ??
//         LinearGradient(colors: [boxColor, boxColor.withValues(alpha: 0.8)]);

//     return Material(
//       color: Colors.transparent,
//       borderRadius: BorderRadius.circular(20),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(20),
//         splashColor: boxColor.withValues(alpha: 0.2),
//         highlightColor: boxColor.withValues(alpha: 0.1),
//         child: Ink(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 boxColor.withValues(alpha: 0.15),
//                 boxColor.withValues(alpha: 0.08),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: boxColor.withValues(alpha: 0.3)),
//             boxShadow: [
//               BoxShadow(
//                 color: boxColor.withValues(alpha: 0.1),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   if (icon != null) ...[
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         gradient: boxGradient,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: boxColor.withValues(alpha: 0.3),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Icon(icon, size: 20, color: Colors.white),
//                     ),
//                     Text(
//                       isLoading ? "..." : number,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: isLoading ? 20 : 28,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: -0.5,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ],
//               ),
//               const Spacer(),
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: Colors.white.withValues(alpha: 0.7),
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // SECTION 3: Route Plan with Today's Progress
// class RoutePlanSection extends StatelessWidget {
//   const RoutePlanSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ProviderRoute>(
//       builder: (context, routeProvider, child) {
//         if (routeProvider.isLoading) {
//           return Center(
//             child: Padding(
//               padding: const EdgeInsets.all(32),
//               child: Column(
//                 children: [
//                   CircularProgressIndicator(
//                     color: AppColors.primaryRed,
//                     strokeWidth: 3,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     LocaleKeys.loadingRoutes.tr(),
//                     style: TextStyle(
//                       color: Colors.white.withValues(alpha: 0.7),
//                       fontSize: 13,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         final stops = routeProvider.todaysStopsList;

//         // No route case - simplified without progress
//         if (stops.isEmpty) {
//           return Container(
//             padding: const EdgeInsets.all(20),

//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             AppColors.primaryRed.withValues(alpha: 0.2),
//                             AppColors.primaryRed.withValues(alpha: 0.1),
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Icon(
//                         Icons.route_outlined,
//                         color: AppColors.primaryRed,
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       LocaleKeys.your_route_plan.tr(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         letterSpacing: -0.5,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 Container(
//                   padding: const EdgeInsets.all(40),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.03),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withValues(alpha: 0.05),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.calendar_today_outlined,
//                           size: 40,
//                           color: Colors.white.withValues(alpha: 0.3),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         LocaleKeys.no_route_today.tr(),
//                         style: TextStyle(
//                           color: Colors.white.withValues(alpha: 0.7),
//                           fontSize: 15,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         // Has route - show progress + route items
//         return Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           AppColors.primaryRed.withValues(alpha: 0.2),
//                           AppColors.primaryRed.withValues(alpha: 0.1),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       Icons.route_outlined,
//                       color: AppColors.primaryRed,
//                       size: 20,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           LocaleKeys.your_route_plan.tr(),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                             letterSpacing: -0.5,
//                           ),
//                         ),
//                         Text(
//                           LocaleKeys.todays_schedule.tr(),
//                           style: TextStyle(
//                             color: Colors.white.withValues(alpha: 0.5),
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           AppColors.primaryRed,
//                           AppColors.primaryRed.withValues(alpha: 0.8),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.primaryRed.withValues(alpha: 0.4),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Text(
//                       '${routeProvider.completedStops}/${stops.length}',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               // const SizedBox(height: 20),

//               // Today's Progress Card
//               Container(
//                 // padding: const EdgeInsets.all(12),
//                 // decoration: BoxDecoration(
//                 //   gradient: LinearGradient(
//                 //     colors: [
//                 //       AppColors.primaryRed.withValues(alpha: 0.15),
//                 //       AppColors.primaryRed.withValues(alpha: 0.05),
//                 //     ],
//                 //   ),
//                 //   borderRadius: BorderRadius.circular(12),
//                 //   border: Border.all(
//                 //     color: AppColors.primaryRed.withValues(alpha: 0.3),
//                 //   ),
//                 // ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Row(
//                     //   children: [
//                     //     Container(
//                     //       padding: const EdgeInsets.all(6),
//                     //       decoration: BoxDecoration(
//                     //         color: AppColors.primaryRed.withValues(alpha: 0.2),
//                     //         borderRadius: BorderRadius.circular(8),
//                     //       ),
//                     //       child: Icon(
//                     //         Icons.today,
//                     //         color: AppColors.primaryRed,
//                     //         size: 16,
//                     //       ),
//                     //     ),
//                     //     const SizedBox(width: 8),
//                     //     Expanded(
//                     //       child: Text(
//                     //         LocaleKeys.todays_progress.tr(),
//                     //         style: const TextStyle(
//                     //           color: Colors.white,
//                     //           fontSize: 14,
//                     //           fontWeight: FontWeight.w600,
//                     //         ),
//                     //       ),
//                     //     ),
//                     //     Container(
//                     //       padding: const EdgeInsets.symmetric(
//                     //         horizontal: 10,
//                     //         vertical: 4,
//                     //       ),
//                     //       decoration: BoxDecoration(
//                     //         gradient: LinearGradient(
//                     //           colors: [
//                     //             AppColors.primaryRed,
//                     //             AppColors.primaryRed.withValues(alpha: 0.8),
//                     //           ],
//                     //         ),
//                     //         borderRadius: BorderRadius.circular(10),
//                     //       ),
//                     //       child: Text(
//                     //         '${(routeProvider.todaysProgressValue * 100).toStringAsFixed(0)}%',
//                     //         style: const TextStyle(
//                     //           color: Colors.white,
//                     //           fontSize: 13,
//                     //           fontWeight: FontWeight.bold,
//                     //         ),
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
//                     const SizedBox(height: 10),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Stack(
//                         children: [
//                           Container(
//                             height: 8,
//                             color: Colors.white.withValues(alpha: 0.1),
//                           ),
//                           FractionallySizedBox(
//                             widthFactor: routeProvider.todaysProgressValue,
//                             child: Container(
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: [
//                                     AppColors.primaryRed,
//                                     AppColors.primaryRed.withValues(alpha: 0.8),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.check_circle,
//                           size: 12,
//                           color: AppColors.primaryRed,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${routeProvider.todaysCompletedCount} / ${stops.length} ${LocaleKeys.branches_checked.tr()}',
//                           style: TextStyle(
//                             color: Colors.white.withValues(alpha: 0.7),
//                             fontSize: 11.5,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Route Items List
//               ...stops.asMap().entries.map((entry) {
//                 return TweenAnimationBuilder<double>(
//                   duration: Duration(milliseconds: 400 + (entry.key * 100)),
//                   tween: Tween(begin: 0.0, end: 1.0),
//                   curve: Curves.easeOutCubic,
//                   builder: (context, value, child) {
//                     return Opacity(
//                       opacity: value,
//                       child: Transform.translate(
//                         offset: Offset(0, 20 * (1 - value)),
//                         child: child,
//                       ),
//                     );
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.only(bottom: 16),
//                     child: DailyRouteCard(
//                       stop: entry.value,
//                       onTap: () {
//                         if (entry.value.status == AppConstants.completed) {
//                           showSnakBarr(
//                             context,
//                             LocaleKeys.youHaveAlreadyCompleted.tr(),
//                           );
//                           return;
//                         }

//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => ScreenSubmitReport(
//                               branchId: entry.value.branchId,
//                               branchTemplateId: entry.value.branchTemplateId,
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class DailyRouteCard extends StatelessWidget {
//   final RouteStopModel stop;
//   final VoidCallback? onTap;

//   const DailyRouteCard({super.key, required this.stop, this.onTap});

//   StopStatus getStatus() {
//     if (stop.isCompleted) {
//       return StopStatus(
//         text: LocaleKeys.completed.tr(),
//         color: Colors.green,
//         icon: Icons.check_circle,
//       );
//     } else {
//       return StopStatus(
//         text: LocaleKeys.waiting.tr(),
//         color: Colors.amber,
//         icon: Icons.hourglass_bottom,
//       );
//     }
//   }

//   Widget _buildInfoColumn({
//     required IconData icon,
//     required Color iconColor,
//     required String label,
//     required String value,
//     CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
//   }) {
//     return Column(
//       crossAxisAlignment: crossAxisAlignment,
//       children: [
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(7),
//               decoration: BoxDecoration(
//                 color: iconColor.withValues(alpha: 0.15),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(icon, size: 16, color: iconColor),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 color: AppColors.white.withValues(alpha: 0.6),
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 6),
//         Padding(
//           padding: const EdgeInsets.only(left: 4),
//           child: Text(
//             value,
//             style: const TextStyle(
//               color: AppColors.white,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final status = getStatus();

//     return Material(
//       color: Colors.transparent,
//       borderRadius: BorderRadius.circular(20),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(20),
//         onTap: onTap,
//         splashColor: status.color.withValues(alpha: 0.1),
//         highlightColor: status.color.withValues(alpha: 0.05),
//         child: Ink(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 AppColors.lightBlack,
//                 AppColors.lightBlack.withValues(alpha: 0.8),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: status.color.withValues(alpha: 0.3)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.2),
//                 blurRadius: 15,
//                 offset: const Offset(0, 5),
//               ),
//               BoxShadow(
//                 color: status.color.withValues(alpha: 0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       status.color.withValues(alpha: 0.15),
//                       status.color.withValues(alpha: 0.05),
//                     ],
//                   ),
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     topRight: Radius.circular(20),
//                   ),
//                   border: Border(
//                     left: BorderSide(width: 4, color: status.color),
//                   ),
//                 ),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             stop.branchName,
//                             style: const TextStyle(
//                               color: AppColors.white,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               letterSpacing: -0.3,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           if (stop.branchAddress != null)
//                             Text(
//                               stop.branchAddress!,
//                               style: TextStyle(
//                                 color: AppColors.whiteWithOpacity(0.6),
//                                 fontSize: 10,
//                                 letterSpacing: -0.3,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 5,
//                       ),
//                       decoration: BoxDecoration(
//                         color: status.color.withValues(alpha: 0.15),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: status.color.withValues(alpha: 0.4),
//                         ),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(status.icon, size: 13, color: status.color),
//                               const SizedBox(width: 5),
//                               Text(
//                                 status.text,
//                                 style: TextStyle(
//                                   color: status.color,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           if (stop.completedAt != null)
//                             Text(
//                               DateFormat(
//                                 'MMMM d, yyyy \'at\' h:mm a',
//                               ).format(stop.completedAt!),
//                               style: TextStyle(
//                                 color: AppColors.white.withValues(alpha: 0.6),
//                                 fontSize: 8,
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Content Section
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (stop.createdAt != null)
//                       Expanded(
//                         child: _buildInfoColumn(
//                           icon: Icons.calendar_today_rounded,
//                           iconColor: AppColors.primaryRed,
//                           label: LocaleKeys.assigned_at.tr(),
//                           value: DateFormat(
//                             'MMMM d, yyyy \'at\' h:mm a',
//                           ).format(stop.createdAt!),
//                         ),
//                       ),

//                     if (stop.isCompleted) ...[
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _buildInfoColumn(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           icon: Icons.star_rounded,
//                           iconColor: AppColors.amber,
//                           label: LocaleKeys.score.tr(),
//                           value: stop.inspectionScore != null
//                               ? '${stop.inspectionScore}'
//                               : '-',
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class StopStatus {
//   final String text;
//   final Color color;
//   final IconData icon;

//   const StopStatus({
//     required this.text,
//     required this.color,
//     required this.icon,
//   });
// }
