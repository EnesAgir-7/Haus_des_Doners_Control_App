import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/provider_route.dart';
import '../../translations/locale_keys.g.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  Future<void> _selectDate(BuildContext context, ProviderRoute provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: context.locale,
      initialDate: provider.filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return child!;
      },
    );

    if (picked != null) {
      provider.setDateFilter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<ProviderRoute>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(routeProvider),
            Expanded(child: _buildRouteContent(routeProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProviderRoute provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: [AppColors.primaryRed, AppColors.primaryRed.withValues(alpha: 0.8)],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.upcoming_routes.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (provider.allRoute != null)
                      Row(
                        children: [
                          if (provider.filterDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_alt,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    LocaleKeys.filtered.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (provider.filterDate != null)
                            const SizedBox(width: 8),
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
                              DateFormat('EEEE').format(
                                provider.filterDate ?? provider.selectedDate,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM d, yyyy').format(
                              provider.filterDate ?? provider.selectedDate,
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (provider.allRoute != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.location_on,
                          label:
                              '${provider.filteredStops.length} ${LocaleKeys.stops.tr()}',
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.check_circle,
                          label:
                              '${provider.filteredCompletedCount} ${LocaleKeys.done.tr()}',
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.pending,
                          label:
                              '${provider.filteredStops.length - provider.filteredCompletedCount} ${LocaleKeys.left.tr()}',
                          color: Colors.orange.shade300,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _selectDate(context, provider),
                    tooltip: LocaleKeys.select_date.tr(),
                  ),
                ),
                if (provider.filterDate != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => provider.clearDateFilter(),
                      tooltip: LocaleKeys.show_all_routes.tr(),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.filteredProgressValue,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteContent(ProviderRoute provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (provider.allRoute == null || provider.stops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.no_route_today.tr(),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final displayStops = provider.filteredStops;

    if (displayStops.isEmpty && provider.filterDate != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.no_stops_for_date.tr(),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.clearDateFilter(),
              icon: const Icon(Icons.clear),
              label: Text(LocaleKeys.show_all_routes.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () async {
        await provider.fetchAllRoutes();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: displayStops.length,
        itemBuilder: (context, index) {
          final stop = displayStops[index];
          final isFirst = index == 0;
          final isLast = index == displayStops.length - 1;

          return _buildRouteStopItem(
            stop: stop,
            index: index,
            isFirst: isFirst,
            isLast: isLast,
          );
        },
      ),
    );
  }

  Widget _buildRouteStopItem({
    required stop,
    required int index,
    required bool isFirst,
    required bool isLast,
  }) {
    final isCompleted = stop.status == AppConstants.completed;

    // Check if this stop is for today
    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month}-${today.day}";
    final isToday = stop.timeSlot == todayKey;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusLabel = LocaleKeys.completed.tr();
    } else if (isToday) {
      statusColor = AppColors.primaryRed;
      statusIcon = Icons.hourglass_bottom;
      statusLabel = LocaleKeys.waiting.tr();
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.radio_button_unchecked;
      statusLabel = LocaleKeys.pending.tr();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isCompleted ? Colors.green : Colors.grey.shade300,
                            isCompleted ? Colors.green : Colors.grey.shade300,
                          ],
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 3),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: statusColor, size: 20)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isCompleted ? Colors.green : Colors.grey.shade300,
                            isCompleted && index < index + 1
                                ? Colors.green
                                : Colors.grey.shade300,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                bottom: isLast ? 0 : 24,
                top: isFirst ? 0 : 0,
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.transparent),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: (isToday
                        ? LinearGradient(
                            colors: [
                              AppColors.primaryRed,
                              AppColors.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stop.branchName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: null,
                                ),
                              ),
                            ),
                            if (isToday)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.shade400,
                                      Colors.green.shade400,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.today,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      LocaleKeys.today.tr(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeSlot(stop.timeSlot),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (isToday) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to inspection
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(LocaleKeys.start_inspection.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeSlot(String timeSlot) {
    try {
      final parts = timeSlot.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(year, month, day);

        // Format: "Monday, Oct 7"
        return DateFormat('EEEE, MMM d yyyy').format(date);
      }
    } catch (e) {
      // If parsing fails, return original
    }
    return timeSlot;
  }
}
