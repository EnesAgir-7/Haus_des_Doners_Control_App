import 'package:flutter/material.dart';
import 'package:haus_des_control/widgets/statistic_card.dart';

class AdminDashboard extends StatelessWidget {
  AdminDashboard({super.key});

  final List<StatisticCard> taskList = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemCount: taskList.length,
            itemBuilder: (context, index) {
              return taskList[index];
            },
          ),
        ),
      ],
    );
  }
}
