import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_branches.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/providers/provider_tasks.dart';
import '../admin_providers/provider_admin_bottombar.dart';
import '../admin_providers/provider_admin_fleet.dart';
import '../widgets/admin_recent_inspections_section.dart';

class ScreenAdminHome extends StatefulWidget {
  const ScreenAdminHome({super.key});

  @override
  State<ScreenAdminHome> createState() => _ScreenAdminHomeState();
}

class _ScreenAdminHomeState extends State<ScreenAdminHome>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                DashboardCard(),
                const SizedBox(height: 24),
                const InspectionSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with admin info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed.withValues(alpha: 0.2),
                      AppColors.primaryRed.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primaryRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loggedInUser?.name ?? LocaleKeys.admin_name.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocaleKeys.admin_panel.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              Selector<ProviderAdminBranches, Tuple2<bool, int>>(
                selector: (_, provider) =>
                    Tuple2(provider.isLoading, provider.branches.length),
                builder: (_, data, __) {
                  final isLoading = data.item1;
                  final count = data.item2;
                  return StatBox(
                    onTap: () {
                      context.read<AdminBottomNavProvider>().onItemTapped(2);
                    },
                    textSize: isLoading ? 10 : 28,
                    number: isLoading ? LocaleKeys.loading.tr() : count.toString(),
                    label: LocaleKeys.total_branches.tr(),
                    icon: Icons.apartment_outlined,
                    color: Colors.blue,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    ),
                  );
                },
              ),
              Selector<ProviderAdminUsers, Tuple2<bool, int>>(
                selector: (_, provider) =>
                    Tuple2(provider.isLoading, provider.inspectors.length),
                builder: (_, data, __) {
                  final isLoading = data.item1;
                  final count = data.item2;
                  return StatBox(
                    onTap: () {
                      context.read<AdminBottomNavProvider>().onItemTapped(1);
                    },
                    textSize: isLoading ? 10 : 28,
                    number: isLoading ? LocaleKeys.loading.tr() : count.toString(),
                    label: LocaleKeys.total_users.tr(),
                    icon: Icons.people_outline,
                    color: Colors.green,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                    ),
                  );
                },
              ),
              Selector<ProviderTasks, Tuple2<bool, int>>(
                selector: (_, provider) =>
                    Tuple2(provider.isLoading, provider.tasks.length),
                builder: (_, data, __) {
                  final isLoading = data.item1;
                  final count = data.item2;
                  return StatBox(
                    onTap: () {
                      context.read<AdminBottomNavProvider>().onItemTapped(4);
                    },
                    textSize: isLoading ? 10 : 28,
                    number: isLoading ? LocaleKeys.loading.tr() : count.toString(),
                    label: LocaleKeys.total_tasks.tr(),
                    icon: Icons.task_outlined,
                    color: Colors.orange,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    ),
                  );
                },
              ),
              Selector<ProviderAdminVehicles, Tuple2<bool, int>>(
                selector: (_, provider) =>
                    Tuple2(provider.isLoading, provider.vehicles.length),
                builder: (_, data, __) {
                  final isLoading = data.item1;
                  final count = data.item2;
                  return StatBox(
                    onTap: () {
                      context.read<AdminBottomNavProvider>().onItemTapped(3);
                    },
                    textSize: isLoading ? 10 : 28,
                    number: isLoading ? LocaleKeys.loading.tr() : count.toString(),
                    label: LocaleKeys.total_fleet.tr(),
                    icon: Icons.directions_car_outlined,
                    color: AppColors.amber,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.amber,
                        AppColors.amber.withValues(alpha: 0.8),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final Color color;
  final Gradient gradient;
  final VoidCallback? onTap;
  final double? textSize;

  const StatBox({
    super.key,
    required this.number,
    required this.label,
    required this.icon,
    required this.color,
    required this.gradient,
    this.onTap,
    this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                  Text(
                    number,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize ?? 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
