import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

void showSnakBarr(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.primaryRed,
      duration: const Duration(seconds: 3),
    ),
  );
}

// enum ToastType { success, error, warning }
// showSnakBarr(
//   String message, {
//   ToastType type = ToastType.success,
//   Duration duration = const Duration(seconds: 3),
//   required BuildContext context,
//   String? actionText,
//   VoidCallback? onActionTap,
// }) {
//   Color backgroundColor;

//   switch (type) {
//     case ToastType.success:
//       backgroundColor = AppColors.amber;
//       break;
//     case ToastType.error:
//       backgroundColor = AppColors.primaryRed;

//       break;
//     case ToastType.warning:
//       backgroundColor = AppColors.alertColor;
//       break;
//   }

//   ScaffoldMessenger.of(context).hideCurrentSnackBar();
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       duration: onActionTap != null ? Duration(seconds: 5) : duration,
//       backgroundColor: backgroundColor,
//       content: Text(
//         message,
//       ),
//       action: actionText != null && onActionTap != null
//           ? SnackBarAction(
//               label: actionText,
//               onPressed: onActionTap,
//               textColor: AppColors.white,
//             )
//           : null,
//     ),
//   );
// }
