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

class ScreenRoutes extends StatefulWidget {
  const ScreenRoutes({super.key});

  @override
  State<ScreenRoutes> createState() => _ScreenRoutesState();
}

class _ScreenRoutesState extends State<ScreenRoutes> {
  Future<void> _selectDate(BuildContext context, ProviderRoute provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: context.locale,
      initialDate: provider.filterDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
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
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (provider.filterDate == null) ...[
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
              ],
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
          if (provider.allRoute != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 4,
                      children: [
                        _buildStatChip(
                          icon: Icons.location_on,
                          label:
                              '${provider.filteredStops.length} ${LocaleKeys.stops.tr()}',
                          color: Colors.white,
                        ),
                        _buildStatChip(
                          icon: Icons.check_circle,
                          label:
                              '${provider.filteredCompletedCount} ${LocaleKeys.done.tr()}',
                          color: Colors.green.shade300,
                        ),
                        _buildStatChip(
                          icon: Icons.pending,
                          label:
                              '${provider.filteredStops.length - provider.filteredCompletedCount} ${LocaleKeys.left.tr()}',
                          color: Colors.orange.shade300,
                        ),
                        if (provider.filteredOverdueCount > 0)
                          _buildStatChip(
                            icon: Icons.alarm,
                            label:
                                '${provider.filteredOverdueCount} ${LocaleKeys.overdue.tr()}',
                            color: Colors.orange.shade300,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.filteredProgressValue,
                backgroundColor: AppColors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
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
        borderRadius: BorderRadius.circular(6),
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
        gradient: LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    if (isToday) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
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
            offset: Offset(0, 2),
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
            style: TextStyle(
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
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
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
            style: TextStyle(
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
