import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FleetPage extends StatelessWidget {
  const FleetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionTitle(icon: Icons.local_shipping, title: "Filo Yönetimi"),
              SizedBox(height: 12),
              _CurrentVehicleCard(),
              SizedBox(height: 16),
              _VehicleDetailsCard(),
              SizedBox(height: 24),
              _SectionTitle(
                icon: Icons.directions_car,
                title: "Diğer Kontrolcü Araçları",
              ),
              SizedBox(height: 12),
              _OtherVehiclesList(),
              SizedBox(height: 16),
              _ActionButtons(),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key, color: AppColors.primaryRed, size: 18),
              SizedBox(width: 6),
              Text(
                "Mevcut Kiralık Araç",
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            "Kontrolcü: Mehmet Yılmaz",
            style: TextStyle(color: AppColors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

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
            children: const [
              Expanded(
                child: _StatBox(value: "15,420", label: "Mevcut KM"),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatBox(value: "25,000", label: "Maksimum KM"),
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
          const Text(
            "Kalan KM:",
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "9,580 km",
            style: TextStyle(
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
          const Text(
            "%62 kullanıldı",
            style: TextStyle(color: AppColors.lightGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReturnDate extends StatelessWidget {
  const _ReturnDate();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "İade Tarihi",
              style: TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "15 Ekim 2025",
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.warning, color: AppColors.primaryRed, size: 16),
                SizedBox(width: 4),
                Text(
                  "5 gün kaldı",
                  style: TextStyle(color: AppColors.primaryRed, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        Icon(Icons.calendar_month, color: AppColors.white, size: 32),
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
      children: const [
        _OtherVehicleCard(
          name: "Ahmet Demir - Renault Kangoo",
          plate: "34 DEF 5678",
          currentKm: 8500,
          maxKm: 20000,
          returnDate: "22 Ekim",
          progressColor: Colors.green,
        ),
        _OtherVehicleCard(
          name: "Fatma Özkan - Ford Transit",
          plate: "34 GHI 9012",
          currentKm: 18200,
          maxKm: 25000,
          returnDate: "30 Ekim",
          progressColor: Colors.amber,
        ),
        _OtherVehicleCard(
          name: "Osman Kaya - Fiat Doblo",
          plate: "34 JKL 3456",
          currentKm: 22800,
          maxKm: 24000,
          returnDate: "12 Ekim",
          progressColor: AppColors.primaryRed,
        ),
        _OtherVehicleCard(
          name: "Zehra Aksoy - Opel Combo",
          plate: "34 MNO 7890",
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
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightRed,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            child: const Text(
              "KM Güncelle",
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            child: const Text(
              "Araç Değiştir",
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
