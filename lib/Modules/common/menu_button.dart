import 'package:flutter/material.dart';

PopupMenuItem<String> buildMenuItem({
  required String value,
  required IconData icon,
  required String title,
  required Color color,
}) {
  return PopupMenuItem<String>(
    value: value,
    padding: EdgeInsets.zero,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

PopupMenuItem<String> buildDivider() {
  return PopupMenuItem<String>(
    enabled: false,
    padding: EdgeInsets.zero,
    height: 1,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
    ),
  );
}
