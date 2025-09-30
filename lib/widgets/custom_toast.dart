import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
enum ToastType { success, error, warning }

showSnakBarr(
  String message, {
  ToastType type = ToastType.success,
  Duration duration = const Duration(seconds: 3),
  required BuildContext context,
  String? actionText,
  VoidCallback? onActionTap,
}) {
  Color backgroundColor;

  switch (type) {
    case ToastType.success:
      backgroundColor = AppColors.amber;
      break;
    case ToastType.error:
      backgroundColor = AppColors.primaryRed;
      
      break;
    case ToastType.warning:
      backgroundColor = AppColors.alertColor;
      break;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: onActionTap != null ? Duration(seconds: 5) : duration,
      backgroundColor: backgroundColor,
      content: Text(
        message,
      ),
      action: actionText != null && onActionTap != null
          ? SnackBarAction(
              label: actionText,
              onPressed: onActionTap,
              textColor: AppColors.white,
            )
          : null,
    ),
  );
}
