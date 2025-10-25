import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../../../models/vehicle_model.dart';
import '../../common/widget_vehicle_common.dart';
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


