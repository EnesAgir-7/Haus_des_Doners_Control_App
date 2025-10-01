import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../translations/locale_keys.g.dart';
import '../../widgets/app_button.dart';

class FleetPage extends StatelessWidget {
  const FleetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.local_shipping,
                title: LocaleKeys.fleet_management.tr(),
              ),
              const SizedBox(height: 12),
              const _CurrentVehicleCard(),
              const SizedBox(height: 16),
              const _VehicleDetailsCard(),
              const SizedBox(height: 24),
              _SectionTitle(
                icon: Icons.directions_car,
                title: LocaleKeys.other_controller_vehicles.tr(),
              ),
              const SizedBox(height: 12),
              const _OtherVehiclesList(),
              const SizedBox(height: 16),
              const _ActionButtons(isUpdating: false, isChangingVehicle: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// -------------------- Current Vehicle Card --------------------
class _CurrentVehicleCard extends StatelessWidget {
  const _CurrentVehicleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key, color: AppColors.primaryRed, size: 18),
              const SizedBox(width: 6),
              Text(
                LocaleKeys.current_rented_vehicle.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            LocaleKeys.controller_name.tr(),
            style: const TextStyle(color: AppColors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// -------------------- Vehicle Details Card --------------------
class _VehicleDetailsCard extends StatelessWidget {
  const _VehicleDetailsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _VehicleInfo(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:  [
              Expanded(
                child: _StatBox(
                  value: "15,420",
                  label: LocaleKeys.current_km.tr(),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatBox(value: "25,000", label: LocaleKeys.max_km.tr()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _RemainingKm(),
          const SizedBox(height: 16),
          const _ReturnDate(),
        ],
      ),
    );
  }
}

// -------------------- Vehicle Info --------------------
class _VehicleInfo extends StatelessWidget {
  const _VehicleInfo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.directions_car, color: AppColors.white, size: 28),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ford Transit Connect",
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "Plaka: 34 ABC 1234",
              style: TextStyle(color: AppColors.lightGrey, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------- Stat Box --------------------
class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// -------------------- Remaining KM --------------------
class _RemainingKm extends StatelessWidget {
  const _RemainingKm();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.remaining_km.tr(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.remaining_km_value.tr(),
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.62,
              minHeight: 8,
              backgroundColor: AppColors.lightRed,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryRed),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.used_percentage.tr(),
            style: const TextStyle(color: AppColors.lightGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// -------------------- Return Date --------------------
class _ReturnDate extends StatelessWidget {
  const _ReturnDate();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.return_date.tr(),
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              LocaleKeys.return_date_value.tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: AppColors.primaryRed,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  LocaleKeys.days_left.tr(),
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Icon(Icons.calendar_month, color: AppColors.white, size: 32),
      ],
    );
  }
}

// -------------------- Other Vehicles List --------------------
class _OtherVehiclesList extends StatelessWidget {
  const _OtherVehiclesList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children:  [
        _OtherVehicleCard(
          name: LocaleKeys.vehicle_ahmet.tr(),
          plate: LocaleKeys.plate_ahmet.tr(),
          currentKm: 8500,
          maxKm: 20000,
          returnDate: "22 Ekim",
          progressColor: Colors.green,
        ),
        _OtherVehicleCard(
          name: LocaleKeys.vehicle_fatma.tr(),
          plate: LocaleKeys.plate_fatma.tr(),
          currentKm: 18200,
          maxKm: 25000,
          returnDate: "30 Ekim",
          progressColor: Colors.amber,
        ),
        _OtherVehicleCard(
          name: LocaleKeys.vehicle_osman.tr(),
          plate: LocaleKeys.plate_osman.tr(),
          currentKm: 22800,
          maxKm: 24000,
          returnDate: "12 Ekim",
          progressColor: AppColors.primaryRed,
        ),
        _OtherVehicleCard(
          name: LocaleKeys.vehicle_zehra.tr(),
          plate: LocaleKeys.plate_zehra.tr(),
          currentKm: 5300,
          maxKm: 18000,
          returnDate: "05 Kasım",
          progressColor: Colors.green,
        ),
      ],
    );
  }
}

// -------------------- Action Buttons --------------------
class _ActionButtons extends StatelessWidget {
  final bool isUpdating;
  final bool isChangingVehicle;

  const _ActionButtons({
    this.isUpdating = false,
    this.isChangingVehicle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: LocaleKeys.update_km.tr(),
            isLoading: isUpdating,
            onPressed: () {},
            backgroundColor: AppColors.lightRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            text: LocaleKeys.change_vehicle.tr(),
            isLoading: isChangingVehicle,
            onPressed: () {},
            backgroundColor: AppColors.primaryRed,
          ),
        ),
      ],
    );
  }
}


// -------------------- Other Vehicle Card --------------------

class _OtherVehicleCard extends StatelessWidget {
  final String name;
  final String plate;
  final int currentKm;
  final int maxKm;
  final String returnDate;
  final Color progressColor;

  const _OtherVehicleCard({
    required this.name,
    required this.plate,
    required this.currentKm,
    required this.maxKm,
    required this.returnDate,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentKm / maxKm;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plate,
            style: const TextStyle(color: AppColors.lightGrey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            "KM: $currentKm / $maxKm",
            style: const TextStyle(color: AppColors.white, fontSize: 13),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.lightRed,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "İade: $returnDate",
            style: const TextStyle(color: AppColors.lightGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
