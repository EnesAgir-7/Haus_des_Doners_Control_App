import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/vehicle_model.dart';
import '../../translations/locale_keys.g.dart';

class VehicleListCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback? onTap;

  const VehicleListCard({super.key, required this.vehicle, this.onTap});

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12.0),
            _buildKmAndUsage(),
            const SizedBox(height: 12.0),
            _buildServiceInfo(),
            const SizedBox(height: 12.0),
            _buildStatusAndAssigned(),
          ],
        ),
      ),
    );
  }

  /// Header: plate number and model
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.directions_car, color: Colors.white, size: 24.0),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.plate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                vehicle.model,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13.0),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  /// Vehicle status badge
  Widget _buildStatusBadge() {
    Color badgeColor;
    switch (vehicle.status.toLowerCase()) {
      case 'assigned':
        badgeColor = Colors.orange;
        break;
      case 'maintenance':
        badgeColor = Colors.blueGrey;
        break;
      case 'available':
      default:
        badgeColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        vehicle.status.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Displays KM details and usage percentage
  Widget _buildKmAndUsage() {
    // ✅ Calculate the USED percentage (inverse of remaining)
    final usedPercent = 100 - vehicle.remainingPercent;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKmRow(
            icon: Icons.speed,
            label: LocaleKeys.current_km.tr(),
            value:
                '${NumberFormat('#,###').format(vehicle.currentKm)} ${LocaleKeys.km.tr()}',
          ),
          const SizedBox(height: 8.0),
          _buildKmRow(
            icon: Icons.linear_scale,
            label: LocaleKeys.remaining_km.tr(),
            value:
                '${NumberFormat('#,###').format(vehicle.remainingKm)} ${LocaleKeys.km.tr()}',
          ),
          const SizedBox(height: 12.0),
          // ✅ FIXED: Progress bar shows USED percentage
          LinearProgressIndicator(
            value: usedPercent / 100, // Convert to 0.0-1.0 range
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getUsageColor(usedPercent), // Pass used percentage, not km
            ),
            minHeight: 6.0,
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ Show USED percentage
              Text(
                '${usedPercent}% ${LocaleKeys.used.tr()}',
                style: TextStyle(
                  color: _getUsageColor(usedPercent),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // ✅ Show REMAINING percentage
              Text(
                '${vehicle.remainingPercent}% ${LocaleKeys.remaining.toString()}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKmRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 16.0),
        const SizedBox(width: 8.0),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13.0),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Shows service due info
  Widget _buildServiceInfo() {
    final now = DateTime.now();
    final daysUntilNext = vehicle.nextServiceDue.difference(now).inDays;

    String statusText;
    Color color;

    if (daysUntilNext < 0) {
      statusText = LocaleKeys.daysOverdue.tr().replaceFirst(
        '{days}',
        daysUntilNext.abs().toString(),
      );
      color = Colors.redAccent;
    } else if (daysUntilNext == 0) {
      statusText = LocaleKeys.dueToday.tr();
      color = Colors.orangeAccent;
    } else if (daysUntilNext <= 5) {
      statusText = LocaleKeys.inDays.tr().replaceFirst(
        '{days}',
        daysUntilNext.toString(),
      );
      color = Colors.yellowAccent;
    } else {
      statusText = LocaleKeys.inWeeks.tr().replaceFirst(
        '{weeks}',
        (daysUntilNext ~/ 7).toString(),
      );
      color = Colors.greenAccent;
    }

    return Row(
      children: [
        Icon(Icons.build_circle_outlined, color: color, size: 18.0),
        const SizedBox(width: 8.0),
        Text(
          "${LocaleKeys.nextService.tr()}: ${formatDate(vehicle.nextServiceDue)} ($statusText)",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Shows status and assigned inspector info
  Widget _buildStatusAndAssigned() {
    bool isUnassigned =
        vehicle.assignedInspector == null ||
        vehicle.assignedInspector!.name.isEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, size: 14.0, color: Colors.grey.shade500),
            const SizedBox(width: 6.0),
            Text(
              isUnassigned
                  ? LocaleKeys.unassigned.tr()
                  : vehicle.assignedInspector?.name ?? LocaleKeys.unknown.tr(),
              style: TextStyle(
                color: isUnassigned
                    ? AppColors.primaryRed
                    : Colors.grey.shade400,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
        Text(
          "${LocaleKeys.lastServiced.tr()}: ${formatDate(vehicle.lastServiceDate)}",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.0),
        ),
      ],
    );
  }

  Color _getUsageColor(int usedPercent) {
    if (usedPercent >= 90) return Colors.redAccent; // 90%+ used = CRITICAL
    if (usedPercent >= 70) return Colors.orangeAccent; // 70-89% used = WARNING
    return Colors.greenAccent; // <70% used = GOOD
  }
}
