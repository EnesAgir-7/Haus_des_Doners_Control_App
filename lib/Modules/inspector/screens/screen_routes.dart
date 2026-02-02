import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/route_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../bottom_sheets/stop_info_sheet.dart';
import '../providers/provider_route.dart';

import 'common_methods.dart';
import 'screen_submit_report.dart';

enum RouteFilter {
  all,
  completed,
  overdue,
  day1,
  day2,
  day3,
  day4,
  day5,
  day6,
  day7,
  day8,
}

class ScreenRoutes extends StatefulWidget {
  const ScreenRoutes({super.key});

  @override
  State<ScreenRoutes> createState() => _ScreenRoutesState();
}

class _ScreenRoutesState extends State<ScreenRoutes> {
  RouteFilter _selectedFilter = RouteFilter.day1;

  List<RouteStopModel> _getFilteredStops(ProviderRoute provider) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    List<RouteStopModel> filtered;
    switch (_selectedFilter) {
      case RouteFilter.all:
        filtered = provider.stops;
        break;

      case RouteFilter.completed:
        filtered = provider.stops
            .where((stop) => stop.status == AppConstants.completed)
            .toList();
        break;

      case RouteFilter.overdue:
        filtered = provider.stops.where((stop) {
          if (stop.status == AppConstants.completed) return false;

          final parts = stop.timeSlot.split('-');
          if (parts.length != 3) return false;
          final stopDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );

          return stopDate.isBefore(todayDate);
        }).toList();
        break;

      default:
        // Handle day1 to day8
        final dayOffset = _selectedFilter.index - RouteFilter.day1.index;
        if (dayOffset >= 0 && dayOffset < 8) {
          final targetDate = todayDate.add(Duration(days: dayOffset));
          final targetKey = DateFormat('yyyy-MM-dd').format(targetDate);
          filtered = provider.stops
              .where((stop) => stop.timeSlot == targetKey)
              .toList();
        } else {
          filtered = [];
        }
        break;
    }

    // Sort: Non-completed/non-expired first, then by date
    final sorted = List<RouteStopModel>.from(filtered);
    sorted.sort((a, b) {
      final aBottom = a.isCompleted || a.isExpired;
      final bBottom = b.isCompleted || b.isExpired;

      if (aBottom != bBottom) {
        return aBottom ? 1 : -1;
      }

      // If both are in the same category (bottom or top), sort by date/timeSlot
      final dateCompare = a.timeSlot.compareTo(b.timeSlot);
      if (dateCompare != 0) return dateCompare;

      // If same date, sort by order
      return a.order.compareTo(b.order);
    });

    return sorted;
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case RouteFilter.all:
        return LocaleKeys.no_route_today.tr();
      case RouteFilter.completed:
        return '${LocaleKeys.no.tr()} ${LocaleKeys.completed.tr().toLowerCase()} ${LocaleKeys.stops.tr().toLowerCase()}';
      case RouteFilter.overdue:
        return '${LocaleKeys.no.tr()} ${LocaleKeys.overdue.tr().toLowerCase()} ${LocaleKeys.stops.tr().toLowerCase()}';
      default:
        final dayOffset = _selectedFilter.index - RouteFilter.day1.index;
        if (dayOffset == 0) return LocaleKeys.no_route_today.tr();
        final targetDate = DateTime.now().add(Duration(days: dayOffset));
        final dayName = DateFormat('EEEE').format(targetDate);
        return '${LocaleKeys.no.tr()} ${LocaleKeys.stops.tr().toLowerCase()} $dayName';
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<ProviderRoute>(context);
    final displayStops = _getFilteredStops(routeProvider);

    return Scaffold(
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
        child: Column(
          children: [
            _buildHeader(routeProvider, displayStops),
            Expanded(child: _buildRouteContent(routeProvider, displayStops)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ProviderRoute provider,
    List<RouteStopModel> displayStops,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.transparent,
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
                      Text(
                        DateFormat('MMMM d, yyyy').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
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
              const Icon(
                Icons.info_outline,
                size: 10,
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 4),
              Text(
                LocaleKeys.free_day_info.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final routeProvider = Provider.of<ProviderRoute>(context, listen: false);

    final today = DateTime.now();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: LocaleKeys.all_routes.tr(),
            filter: RouteFilter.all,
            icon: Icons.list,
            count: routeProvider.stops.length,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: LocaleKeys.completed.tr(),
            filter: RouteFilter.completed,
            icon: Icons.check_circle,
            count: _getFilterCount(RouteFilter.completed, routeProvider),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: LocaleKeys.overdue.tr(),
            filter: RouteFilter.overdue,
            icon: Icons.warning,
            count: _getFilterCount(RouteFilter.overdue, routeProvider),
          ),
          const SizedBox(width: 8),
          // Today and next 7 days (Total 8)
          ...List.generate(8, (index) {
            final targetDate = today.add(Duration(days: index));
            final label = index == 0
                ? LocaleKeys.today.tr()
                : _getLocalizedDayName(targetDate);
            final filter = RouteFilter.values[RouteFilter.day1.index + index];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: label,
                filter: filter,
                icon: Icons.calendar_today,
                count: _getFilterCount(filter, routeProvider),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getLocalizedDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return LocaleKeys.monday.tr();
      case DateTime.tuesday:
        return LocaleKeys.tuesday.tr();
      case DateTime.wednesday:
        return LocaleKeys.wednesday.tr();
      case DateTime.thursday:
        return LocaleKeys.thursday.tr();
      case DateTime.friday:
        return LocaleKeys.friday.tr();
      case DateTime.saturday:
        return LocaleKeys.saturday.tr();
      case DateTime.sunday:
        return LocaleKeys.sunday.tr();
      default:
        return '';
    }
  }

  Widget _buildFilterChip({
    required String label,
    required RouteFilter filter,
    required IconData icon,
    required int count,
  }) {
    final isSelected = _selectedFilter == filter;
    final isDayFilter = filter.index >= RouteFilter.day1.index;
    final isFree = count == 0 && isDayFilter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withValues(alpha: 0.8)
              : isFree
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryRed
                : isFree
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFree ? Icons.event_available : icon,
              size: 16,
              color: isFree ? Colors.greenAccent : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                color: isFree ? Colors.greenAccent : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getFilterCount(RouteFilter filter, ProviderRoute provider) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    switch (filter) {
      case RouteFilter.all:
        return provider.stops.length;

      case RouteFilter.completed:
        return provider.stops
            .where((stop) => stop.status == AppConstants.completed)
            .length;

      case RouteFilter.overdue:
        return provider.stops.where((stop) {
          if (stop.status == AppConstants.completed) return false;

          final parts = stop.timeSlot.split('-');
          if (parts.length != 3) return false;
          final stopDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );

          return stopDate.isBefore(todayDate);
        }).length;

      default:
        // Handle day1 to day8
        final dayOffset = filter.index - RouteFilter.day1.index;
        if (dayOffset >= 0 && dayOffset < 8) {
          final targetDate = todayDate.add(Duration(days: dayOffset));
          final targetKey = DateFormat('yyyy-MM-dd').format(targetDate);
          return provider.stops
              .where((stop) => stop.timeSlot == targetKey)
              .length;
        }
        return 0;
    }
  }

  Widget _buildRouteContent(
    ProviderRoute provider,
    List<RouteStopModel> displayStops,
  ) {
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

    if (displayStops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  setState(() => _selectedFilter = RouteFilter.day1),
              icon: const Icon(Icons.today),
              label: Text(LocaleKeys.today.tr()),
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
      onRefresh: provider.refresh,
      child: ListView.builder(
        key: const PageStorageKey('routeList'),
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
    required RouteStopModel stop,
    required int index,
    required bool isFirst,
    required bool isLast,
  }) {
    final isCompleted = stop.status == AppConstants.completed;
    final statusInfo = getStatusInfo(stop, isCompleted);

    return GestureDetector(
      onTap: () {
        showStopInfoBottomSheet(stop, context);
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTimelineIndicator(
              index,
              isFirst,
              isLast,
              isCompleted,
              statusInfo.color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 24),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: _buildCardDecoration(
                      statusInfo.isOverdue,
                      statusInfo.isToday,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWidgetHeader(stop, statusInfo),
                          const SizedBox(height: 8),
                          _buildDateRow(
                            stop.timeSlot,
                            statusInfo.isToday,
                            statusInfo.isOverdue,
                          ),
                          if (isCompleted && stop.completedAt != null) ...[
                            const SizedBox(height: 8),
                            _buildCompletedAtRow(stop.completedAt!.toString()),
                          ],
                          if ((statusInfo.isToday || statusInfo.isOverdue) &&
                              !isCompleted) ...[
                            const SizedBox(height: 12),
                            _buildActionButton(stop, statusInfo.isOverdue),
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
      ),
    );
  }

  Widget _buildTimelineIndicator(
    int index,
    bool isFirst,
    bool isLast,
    bool isCompleted,
    Color statusColor,
  ) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          if (!isFirst)
            Expanded(
              child: Container(
                width: 3,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
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
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration? _buildCardDecoration(bool isOverdue, bool isToday) {
    if (isOverdue) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    if (isToday) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF4CAF50)],
        ),
      );
    }
    return null;
  }

  Widget _buildWidgetHeader(RouteStopModel stop, StatusInfo statusInfo) {
    return Row(
      children: [
        Expanded(
          child: Text(
            stop.branchName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusInfo.isToday ? Colors.white : null,
            ),
          ),
        ),
        if (statusInfo.isOverdue)
          _buildBadge(
            LocaleKeys.missed.tr(),
            Icons.warning_amber_rounded,
            Colors.deepOrange,
            Colors.red,
          ),
        if (statusInfo.isToday && !statusInfo.isOverdue)
          _buildBadge(
            LocaleKeys.today.tr(),
            Icons.today,
            Colors.teal,
            Colors.green,
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusInfo.isToday
                ? Colors.white.withValues(alpha: 0.3)
                : statusInfo.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusInfo.icon,
                size: 14,
                color: statusInfo.isToday ? Colors.white : statusInfo.color,
              ),
              const SizedBox(width: 4),
              Text(
                statusInfo.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusInfo.isToday ? Colors.white : statusInfo.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color1, Color color2) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String timeSlot, bool isToday, bool isOverdue) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: isToday || isOverdue
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          formatTimeSlot(timeSlot),
          style: TextStyle(
            fontSize: 14,
            color: isToday || isOverdue
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedAtRow(String completedAt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.white,
                ),
                const SizedBox(width: 4),
                Text(LocaleKeys.submitted.tr()),
              ],
            ),
          ),
          Text(
            '${DateFormat("MMMM d, h:mm a").format(DateTime.parse(completedAt))}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(RouteStopModel stop, bool isOverdue) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScreenSubmitReport(
                branchId: stop.branchId,
                branchTemplateId: stop.branchTemplateId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.arrow_forward),
        label: Text(
          isOverdue
              ? LocaleKeys.inspect_now.tr()
              : LocaleKeys.start_inspection.tr(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOverdue ? Colors.deepOrange : AppColors.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
