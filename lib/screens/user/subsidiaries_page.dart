import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/branch_card.dart';

class SubsidiariesPage extends StatelessWidget {
  const SubsidiariesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final branches = [
      Branch(
        name: "Haus des Döners - Beyoğlu",
        lastControl: "2 gün önce",
        score: 9.2,
      ),
      Branch(
        name: "Haus des Döners - Şişli",
        lastControl: "1 hafta önce",
        score: 8.7,
      ),
      Branch(
        name: "Haus des Döners - Kadıköy",
        lastControl: "3 gün önce",
        score: 9.5,
      ),
      Branch(
        name: "Haus des Döners - Üsküdar",
        lastControl: "5 gün önce",
        score: 8.3,
      ),
      Branch(
        name: "Haus des Döners - Bakırköy",
        lastControl: "1 gün önce",
        score: 9.0,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.apartment, color: Colors.lightBlueAccent),
                  SizedBox(width: 6),
                  Text(
                    "Şubelerim (40 Şube)",
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
                child: ListView.builder(
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    return BranchCard(branch: branches[index]);
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

