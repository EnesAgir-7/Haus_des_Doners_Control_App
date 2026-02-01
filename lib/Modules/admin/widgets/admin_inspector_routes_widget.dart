import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/route_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/firebase_services/inspector_route_service.dart';
import '../widgets/widgets_admin_branch_details.dart';

class AdminInspectorRoutesWidget extends StatefulWidget {
  final String inspectorId;
  final String inspectorName;

  const AdminInspectorRoutesWidget({
    super.key,
    required this.inspectorId,
    required this.inspectorName,
  });

  @override
  State<AdminInspectorRoutesWidget> createState() =>
      _AdminInspectorRoutesWidgetState();
}

class _AdminInspectorRoutesWidgetState
    extends State<AdminInspectorRoutesWidget> {
  final InspectorRouteService _routeService = InspectorRouteService();
  StreamSubscription<RouteModel?>? _routeSubscription;
  RouteModel? _routeData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  void _loadRoutes() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _routeSubscription?.cancel();
    _routeSubscription = _routeService
        .getAllRoutesStream(widget.inspectorId)
        .listen(
          (route) {
            if (mounted) {
              setState(() {
                _routeData = route;
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = error.toString();
                _isLoading = false;
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _routeSubscription?.cancel();
    super.dispose();
  }

  Map<String, List<RouteStopModel>> _getGroupedRoutes() {
    if (_routeData == null) return {};

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrow = todayDate.add(const Duration(days: 1));

    final Map<String, List<RouteStopModel>> grouped = {
      'today': [],
      'tomorrow': [],
      'upcoming': [],
      'missed': [],
      'completed': [],
    };

    // Get stops for today and next 6 days
    for (int i = 0; i < 7; i++) {
      final targetDate = todayDate.add(Duration(days: i));
      final targetKey = DateFormat('yyyy-MM-dd').format(targetDate);

      final dayStops = _routeData!.stops
          .where((stop) => stop.timeSlot == targetKey)
          .toList();

      for (var stop in dayStops) {
        final stopDate = _parseDate(stop.timeSlot);
        if (stopDate == null) continue;

        if (stop.isCompleted) {
          grouped['completed']!.add(stop);
        } else if (stopDate.isBefore(todayDate)) {
          grouped['missed']!.add(stop);
        } else if (stopDate.isAtSameMomentAs(todayDate)) {
          grouped['today']!.add(stop);
        } else if (stopDate.isAtSameMomentAs(tomorrow)) {
          grouped['tomorrow']!.add(stop);
        } else {
          grouped['upcoming']!.add(stop);
        }
      }
    }

    return grouped;
  }

  void _showStopDetails(RouteStopModel stop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => AdminStopInfoSheet(stop: stop),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.error.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final groupedRoutes = _getGroupedRoutes();

    // Calculate total stops
    final totalStops = groupedRoutes.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    if (totalStops == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.route_outlined,
                color: AppColors.primaryRed,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocaleKeys.upcoming_routes.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                '$totalStops ${LocaleKeys.stops.tr()}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Routes List by Category
        ..._buildCategorizedRoutes(groupedRoutes),
      ],
    );
  }

  List<Widget> _buildCategorizedRoutes(
    Map<String, List<RouteStopModel>> groupedRoutes,
  ) {
    final widgets = <Widget>[];

    // Today
    if (groupedRoutes['today']!.isNotEmpty) {
      widgets.add(
        _buildSectionHeader(
          LocaleKeys.today.tr(),
          Icons.today,
          AppColors.primaryRed,
          groupedRoutes['today']!.length,
        ),
      );
      widgets.addAll(
        groupedRoutes['today']!.map((stop) => _buildRouteCard(stop, 0)),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // Tomorrow
    if (groupedRoutes['tomorrow']!.isNotEmpty) {
      widgets.add(
        _buildSectionHeader(
          LocaleKeys.tomorrow.tr(),
          Icons.event,
          Colors.orange,
          groupedRoutes['tomorrow']!.length,
        ),
      );
      widgets.addAll(
        groupedRoutes['tomorrow']!.map((stop) => _buildRouteCard(stop, 0)),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // Upcoming
    if (groupedRoutes['upcoming']!.isNotEmpty) {
      widgets.add(
        _buildSectionHeader(
          'Upcoming Days',
          Icons.schedule,
          Colors.blue,
          groupedRoutes['upcoming']!.length,
        ),
      );
      widgets.addAll(
        groupedRoutes['upcoming']!.map((stop) => _buildRouteCard(stop, 0)),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // Missed
    if (groupedRoutes['missed']!.isNotEmpty) {
      widgets.add(
        _buildSectionHeader(
          LocaleKeys.overdue.tr(),
          Icons.warning_amber,
          Colors.red,
          groupedRoutes['missed']!.length,
        ),
      );
      widgets.addAll(
        groupedRoutes['missed']!.map((stop) => _buildRouteCard(stop, 0)),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // Completed
    if (groupedRoutes['completed']!.isNotEmpty) {
      widgets.add(
        _buildSectionHeader(
          LocaleKeys.completed.tr(),
          Icons.check_circle,
          Colors.green,
          groupedRoutes['completed']!.length,
        ),
      );
      widgets.addAll(
        groupedRoutes['completed']!.map((stop) => _buildRouteCard(stop, 0)),
      );
    }

    return widgets;
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(RouteStopModel stop, int index) {
    final statusInfo = _getStatusInfo(stop);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final stopDate = _parseDate(stop.timeSlot);
    final isToday = stopDate != null && stopDate.isAtSameMomentAs(todayDate);

    return GestureDetector(
      onTap: () => _showStopDetails(stop),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusInfo.color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showStopDetails(stop),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: statusInfo.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: statusInfo.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(statusInfo.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),

                  // Branch Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stop.branchName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isToday)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryRed,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  LocaleKeys.today.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatTimeSlot(stop.timeSlot),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Status Badge and Arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusInfo.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(
                            color: statusInfo.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo(RouteStopModel stop) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final stopDate = _parseDate(stop.timeSlot);

    if (stop.isExpired) {
      return _StatusInfo(
        label: LocaleKeys.expired.tr(),
        icon: Icons.warning_amber_rounded,
        color: Colors.deepOrange,
        gradientColors: [Colors.deepOrange, Colors.red],
      );
    }

    if (stop.isCompleted) {
      return _StatusInfo(
        label: LocaleKeys.completed.tr(),
        icon: Icons.check_circle,
        color: Colors.green,
        gradientColors: [Colors.green, const Color(0xFF2E7D32)],
      );
    }

    final isToday = stopDate != null && stopDate.isAtSameMomentAs(todayDate);
    final isOverdue = stopDate != null && stopDate.isBefore(todayDate);

    if (isOverdue) {
      return _StatusInfo(
        label: LocaleKeys.overdue.tr(),
        icon: Icons.error_outline,
        color: Colors.red,
        gradientColors: [Colors.red.shade700, Colors.red.shade900],
      );
    }

    if (isToday) {
      return _StatusInfo(
        label: LocaleKeys.today.tr(),
        icon: Icons.today,
        color: AppColors.primaryRed,
        gradientColors: [AppColors.primaryRed, AppColors.primaryDark],
      );
    }

    return _StatusInfo(
      label: LocaleKeys.scheduled.tr(),
      icon: Icons.schedule,
      color: Colors.blue,
      gradientColors: [Colors.blue.shade600, Colors.blue.shade800],
    );
  }

  DateTime? _parseDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return null;
  }

  String _formatTimeSlot(String timeSlot) {
    try {
      final date = _parseDate(timeSlot);
      if (date != null) {
        return DateFormat('EEE, MMM d').format(date);
      }
    } catch (_) {}
    return timeSlot;
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  _StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });
}
