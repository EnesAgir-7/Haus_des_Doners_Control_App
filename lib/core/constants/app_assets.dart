import 'package:flutter/material.dart';

import 'app_colors.dart';

const kAppLogo = 'assets/logo.png';

final shadowDeco = BoxDecoration(
  color: AppColors.lightBlack,
  borderRadius: BorderRadius.circular(16),

  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ],
);
