import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';
import '../../models/vehicle_model.dart';
import '../../translations/locale_keys.g.dart';
import '../screens/screen_admin_vehicle_details.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminVehicleDetailsScreen(vehicle: vehicle),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.plate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehicle.model,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(vehicle.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      LocaleKeys.current_km.tr(),
                      '${vehicle.currentKm} km',
                      Icons.speed,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      LocaleKeys.remaining_km.tr(),
                      '${vehicle.remainingKm} km',
                      Icons.update,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      LocaleKeys.used.tr(),
                      '${vehicle.usagePercent}%',
                      Icons.pie_chart,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (vehicle.assignedInspectorName != null) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      vehicle.assignedInspectorName!,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        text = LocaleKeys.status_completed.tr();
        break;
      case 'maintenance':
        color = Colors.orange;
        text = LocaleKeys.in_progress.tr();
        break;
      case 'assigned':
        color = AppColors.primaryRed;
        text = LocaleKeys.assigned_to.tr();
        break;
      default:
        color = Colors.grey;
        text = LocaleKeys.unassigned.tr();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
