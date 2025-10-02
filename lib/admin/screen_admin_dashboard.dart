import 'package:flutter/material.dart';
import 'package:haus_des_control/widgets/statistic_card.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../providers/provider_auth.dart';

class AdminDashboard extends StatelessWidget {
  AdminDashboard({super.key});

  final List<StatisticCard> taskList = [
    StatisticCard(
      time: "09:00 - 10:30",
      title: "Branch Inspection - Berlin",
      status: "Completed",
      subtitle: "Score: 9.2",
      statusColor: Colors.green,
      icon: Icons.check_box,
    ),
    StatisticCard(
      time: "11:00 - 12:30",
      title: "Branch Inspection - Munich",
      status: "Completed",
      subtitle: "Score: 8.7",
      statusColor: Colors.green,
      icon: Icons.check_box,
    ),
    StatisticCard(
      time: "14:00 - 15:30",
      title: "Branch Inspection - Hamburg",
      status: "In Progress",
      subtitle: "",
      statusColor: Colors.pink,
      icon: Icons.location_on,
    ),
    StatisticCard(
      time: "16:00 - 17:30",
      title: "Branch Inspection - Frankfurt",
      status: "Pending",
      subtitle: "",
      statusColor: Colors.grey,
      icon: Icons.hourglass_empty,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              // Logout via ProviderAuth
              context.read<ProviderAuth>().logout();
            },
            icon: const Icon(Icons.logout, color: AppColors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.dashboard, color: Colors.lightBlueAccent),
                  const SizedBox(width: 6),
                  Text(
                    "Admin Dashboard", // 🔑 localization key
                    style: const TextStyle(
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemCount: taskList.length,
                  itemBuilder: (context, index) {
                    return taskList[index];
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
