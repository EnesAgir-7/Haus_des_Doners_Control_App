import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

void showSnakBarr(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating, // ✅ Makes it float above content
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.primaryRed,
      duration: const Duration(seconds: 3),
    ),
  );
}

void showCustomSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isError ? Colors.red : AppColors.primaryRed,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto remove after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
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
