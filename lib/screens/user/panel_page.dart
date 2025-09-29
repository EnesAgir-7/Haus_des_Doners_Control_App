import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/statistic_card.dart';

class PanelPage extends StatelessWidget {
  const PanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            DashboardCard(),
            SizedBox(height: 16),
            DailySummarySection(),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.search, color: Colors.lightBlueAccent, size: 20),
              SizedBox(width: 6),
              Text(
                "Mehmet Yılmaz - Kontrolcü",
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Bölge: İstanbul Avrupa",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: const [
              StatBox(number: "40", label: "Toplam Şube"),
              StatBox(number: "12", label: "Bu Hafta Kontrol"),
              StatBox(number: "3", label: "Bekleyen Görev"),
              StatBox(number: "8.5", label: "Ortalama Puan"),
            ],
          ),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String number;
  final String label;

  const StatBox({super.key, required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class DailySummarySection extends StatelessWidget {
  const DailySummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.insert_chart, color: Colors.purpleAccent),
            SizedBox(width: 6),
            Text(
              "Günlük Özet",
              style: TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatisticCard(
          time: "09:30",
          title: "Haus des Döners - Beyoğlu",
          status: "Tamamlandı",
          statusColor: Colors.green,
          subtitle: "Puan: 9.2",
          icon: Icons.check_box,
        ),
        const SizedBox(height: 10),
        StatisticCard(
          time: "14:00",
          title: "Haus des Döners - Şişli",
          status: "Bekliyor",
          statusColor: Colors.amber,
          subtitle: "",
          icon: Icons.hourglass_bottom,
        ),
      ],
    );
  }
}
