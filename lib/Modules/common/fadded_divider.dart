import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';

class FadedDivider extends StatelessWidget {
  final double thickness;
  final double height;
  final Color color;

  const FadedDivider({
    super.key,
    this.thickness = 2,
    this.height = 24,
    this.color = AppColors.primaryRed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: Container(
        height: thickness,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0), // fully transparent at start
              color.withValues(alpha: 0.8), // visible in middle
              color.withValues(alpha: 0), // fully transparent at end
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}
