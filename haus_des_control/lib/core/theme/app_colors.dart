/// This file contains the color constants used throughout the application.
/// All colors are defined as static constants for consistent usage.

import 'package:flutter/material.dart';

/// A utility class that holds all color-related constants and schemes
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  /// Primary Colors
  static const Color primaryDark = Color(0xFF1C1818);    // Dark grey/black
  static const Color primaryRed = Color(0xFFC2292B);     // Brand red
  static const Color white = Color(0xFFFFFFFF);          // Pure white

  /// Utility methods for color opacity variations
  static Color redWithOpacity(double opacity) => primaryRed.withOpacity(opacity);
  static Color darkWithOpacity(double opacity) => primaryDark.withOpacity(opacity);
  
  /// Light theme color scheme
  static final ColorScheme lightColorScheme = ColorScheme(
    primary: primaryRed,
    secondary: primaryDark,
    surface: white,
    background: white,
    error: const Color(0xFFB00020),
    onPrimary: white,
    onSecondary: white,
    onSurface: primaryDark,
    onBackground: primaryDark,
    onError: white,
    brightness: Brightness.light,
  );

  /// Dark theme color scheme - uses primaryDark as the main background
  static final ColorScheme darkColorScheme = ColorScheme(
    primary: primaryRed,
    secondary: white,
    surface: primaryDark,
    background: primaryDark,
    error: const Color(0xFFCF6679),
    onPrimary: white,
    onSecondary: primaryDark,
    onSurface: white,
    onBackground: white,
    onError: primaryDark,
    brightness: Brightness.dark,
  );
}