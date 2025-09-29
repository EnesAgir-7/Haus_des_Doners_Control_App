import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class Branch {
  final String name;
  final String lastControl;
  final double score;

  Branch({required this.name, required this.lastControl, required this.score});
}


class BranchCard extends StatelessWidget {
  final Branch branch;

  const BranchCard({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branch.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Son Kontrol: ${branch.lastControl}",
                style: const TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 13,
                ),
              ),
              Text(
                "Puan: ${branch.score}",
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
