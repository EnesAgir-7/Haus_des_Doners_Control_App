import 'package:flutter/material.dart';
import 'package:haus_des_control/widgets/statistic_card.dart';

import '../../core/constants/app_colors.dart';

class RoutePage extends StatelessWidget {
  RoutePage({super.key});

  final List<StatisticCard> scheduleList = [
    StatisticCard(
      time: "09:00 - 10:30",
      title: "Haus des Döners - Beyoğlu",
      status: "Tamamlandı",
      subtitle: "",
      statusColor: Colors.green,
      icon: Icons.check_box,
    ),
    StatisticCard(
      time: "11:00 - 12:30",
      title: "Haus des Döners - Galata",
      status: "Tamamlandı",
      subtitle: "",
      statusColor: Colors.green,
      icon: Icons.check_box,
    ),
    StatisticCard(
      time: "14:00 - 15:30",
      title: "Haus des Döners - Şişli",
      status: "Şu anki konum",
      subtitle: "",
      statusColor: Colors.pink,
      icon: Icons.location_on,
    ),
    StatisticCard(
      time: "16:00 - 17:30",
      title: "Haus des Döners - Mecidiyeköy",
      status: "Bekliyor",
      subtitle: "",
      statusColor: Colors.grey,
      icon: Icons.hourglass_empty,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.book, color: Colors.lightBlueAccent),
                  SizedBox(width: 6),
                  Text(
                    "Bugünkü Rota Planı",
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  separatorBuilder: (context, index) => SizedBox(height: 10),
                  itemCount: scheduleList.length,
                  itemBuilder: (context, index) {
                    return scheduleList[index];
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
