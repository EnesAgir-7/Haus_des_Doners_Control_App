import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../../../models/vehicle_model.dart';
import '../providers/provider_vehicle.dart';
import 'screen_vehicle.dart';

class ScreenVehiclesList extends StatefulWidget {
  const ScreenVehiclesList({super.key});

  @override
  State<ScreenVehiclesList> createState() => _ScreenVehiclesListState();
}

class _ScreenVehiclesListState extends State<ScreenVehiclesList> {
  // Placeholder constants for sorting, matching the structure of FirebaseConstants
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderVehicle>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Gradient background from ScreenBranches
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
        child: SafeArea(
          child: Consumer<ProviderVehicle>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(provider),

                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 12),
                    Expanded(child: _buildVehicleList(provider)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ProviderVehicle provider) {
    return Row(
      children: [
        const Icon(Icons.car_rental, color: Colors.lightBlueAccent),
        const SizedBox(width: 6),
        Text(
          // Placeholder translation key for 'My Vehicles'
          'My Vehicles',
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            // Placeholder: Assuming the provider has a vehicleCount property
            'Count: ${provider.vehicleCount.toString()}',
            style: TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleList(ProviderVehicle provider) {
    if (provider.isLoadingg) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (provider.errorMessagee != null) {
      return _buildErrorState(provider);
    }

    if (provider.vehicles.isEmpty) {
      return _buildEmptyState(provider);
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AppColors.primaryRed,
      backgroundColor: AppColors.lightBlack,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 50),
        key: const PageStorageKey('vehiclesList'),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.vehicles.length,
        itemBuilder: (context, index) {
          final vehicleModel = provider.vehicles[index];
          return GestureDetector(
            onTap: () => _navigateToVehicleDetails(context, vehicleModel),
            child: VehicleListCard(vehicle: vehicleModel),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ProviderVehicle provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppColors.primaryRed),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.error_occurred.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.errorMessagee!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: Text(LocaleKeys.try_again.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ProviderVehicle provider) {
    return Center(child: Text('No vehicles assigned to you.'));
  }

  void _navigateToVehicleDetails(
    BuildContext context,
    VehicleModel vehicleModel,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScreenVehicle(vehicle: vehicleModel),
      ),
    );
  }
}

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
      case 'in_use':
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
            value: '${vehicle.currentKm} km',
          ),
          const SizedBox(height: 8.0),
          _buildKmRow(
            icon: Icons.linear_scale,
            label: LocaleKeys.remaining_km.tr(),
            value: '${vehicle.remainingKm} km',
          ),
          const SizedBox(height: 8.0),
          LinearProgressIndicator(
            value: vehicle.usagePercent / 100,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getUsageColor(vehicle.usagePercent),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            '${vehicle.usagePercent}% used',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12.0),
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
      statusText = '${daysUntilNext.abs()} days overdue';
      color = Colors.redAccent;
    } else if (daysUntilNext == 0) {
      statusText = "Due today";
      color = Colors.orangeAccent;
    } else if (daysUntilNext <= 5) {
      statusText = "In $daysUntilNext days";
      color = Colors.yellowAccent;
    } else {
      statusText = "In ${daysUntilNext ~/ 7} weeks";
      color = Colors.greenAccent;
    }

    return Row(
      children: [
        Icon(Icons.build_circle_outlined, color: color, size: 18.0),
        const SizedBox(width: 8.0),
        Text(
          "Next Service: ${formatDate(vehicle.nextServiceDue)} ($statusText)",
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (vehicle.assignedInspector != null)
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14.0,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 6.0),
              Text(
                vehicle.assignedInspector!.name,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12.0),
              ),
            ],
          ),
        Text(
          "Last Serviced: ${formatDate(vehicle.lastServiceDate)}",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.0),
        ),
      ],
    );
  }

  Color _getUsageColor(int percent) {
    if (percent >= 95) return Colors.redAccent;
    if (percent >= 70) return Colors.orangeAccent;
    return Colors.greenAccent;
  }
}
