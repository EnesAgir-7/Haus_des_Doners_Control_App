import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/route_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/app_button.dart';

class AdminStopInfoSheet extends StatelessWidget {
  final RouteStopModel stop;

  const AdminStopInfoSheet({super.key, required this.stop});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStopStatusInfo();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, statusInfo),
              const SizedBox(height: 20),
              _buildInfoSection(),
              const SizedBox(height: 16),
              Center(
                child: AppButton(
                  text: LocaleKeys.cancel.tr(),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  borderRadius: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _StopStatusInfo statusInfo) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: statusInfo.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: statusInfo.color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.store, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.branchName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusInfo.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusInfo.icon, size: 14, color: statusInfo.color),
                    const SizedBox(width: 6),
                    Text(
                      statusInfo.label,
                      style: TextStyle(
                        color: statusInfo.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(LocaleKeys.branchName.tr(), stop.branchName),
        _infoRow(
          LocaleKeys.branchAddress.tr(),
          stop.branchAddress ?? LocaleKeys.notAvailable.tr(),
        ),
        _infoRow(LocaleKeys.timeSlot.tr(), formatTimeSlot(stop.timeSlot)),
        _infoRow(LocaleKeys.status.tr(), stop.status),
        if (stop.inspectionScore != null)
          _infoRow(LocaleKeys.inspectionScore.tr(), stop.inspectionScore!),
        if (stop.createdAt != null)
          _infoRow(
            LocaleKeys.createdAt.tr(),
            DateFormat("MMMM d, yyyy 'at' h:mm a").format(stop.createdAt!),
          ),
        if (stop.completedAt != null)
          _infoRow(
            LocaleKeys.completedAt.tr(),
            DateFormat("MMMM d, yyyy 'at' h:mm a").format(stop.completedAt!),
          ),
        if (stop.expiryDate != null)
          _infoRow(
            LocaleKeys.expiryDate.tr(),
            DateFormat(
              "MMMM d, yyyy 'at' h:mm a",
            ).format(stop.expiryDate!.toDate()),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHODS ---

  String formatTimeSlot(String timeSlot) {
    try {
      final date = _parseTimeSlot(timeSlot);
      return date != null ? DateFormat("MMMM d, yyyy").format(date) : timeSlot;
    } catch (e) {
      return timeSlot;
    }
  }

  _StopStatusInfo _getStopStatusInfo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDate = _parseTimeSlot(stop.timeSlot);

    if (stop.isExpired) {
      return _StopStatusInfo(
        label: LocaleKeys.expired.tr(),
        icon: Icons.warning_amber_rounded,
        color: Colors.deepOrange,
        gradientColors: [Colors.deepOrange, Colors.red],
      );
    }
    if (stop.isCompleted) {
      return _StopStatusInfo(
        label: LocaleKeys.completed.tr(),
        icon: Icons.check_circle,
        color: Colors.green,
        gradientColors: [Colors.green, const Color(0xFF2E7D32)],
      );
    }

    final isToday =
        scheduledDate != null && scheduledDate.isAtSameMomentAs(today);
    final isOverdue = scheduledDate != null && scheduledDate.isBefore(today);

    if (isOverdue) {
      return _StopStatusInfo(
        label: LocaleKeys.overdue.tr(),
        icon: Icons.error_outline,
        color: Colors.red,
        gradientColors: [Colors.red.shade700, Colors.red.shade900],
      );
    }
    if (isToday) {
      if (stop.isCurrent) {
        return _StopStatusInfo(
          label: LocaleKeys.inProgress.tr(),
          icon: Icons.play_circle_outline,
          color: Colors.amber,
          gradientColors: [Colors.amber, Colors.orange],
        );
      }
      return _StopStatusInfo(
        label: LocaleKeys.today.tr(),
        icon: Icons.today,
        color: Colors.green,
        gradientColors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
      );
    }
    return _StopStatusInfo(
      label: LocaleKeys.scheduled.tr(),
      icon: Icons.schedule,
      color: Colors.blue,
      gradientColors: [AppColors.primaryRed, AppColors.primaryDark],
    );
  }

  DateTime? _parseTimeSlot(String timeSlot) {
    try {
      return DateTime.parse(timeSlot);
    } catch (e) {
      return null;
    }
  }
}

class _StopStatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  _StopStatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });
}
