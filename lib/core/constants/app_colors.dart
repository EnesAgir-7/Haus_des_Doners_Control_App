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
  static const Color lightRed = Color(0xff362424);     // Brand red
  static const Color white = Color(0xFFFFFFFF);          // Pure white
  static const Color lightBlack = Color(0xFF1A1A1A);          // Pure white
  static const Color lightGrey = Color(0xFFC2C0B6);          // Pure white

  /// Utility methods for color opacity variations
  static Color redWithOpacity(double opacity) => primaryRed.withValues(alpha:  opacity);
  static Color darkWithOpacity(double opacity) => primaryDark.withValues(alpha: opacity);
  static Color whiteWithOpacity(double opacity) => white.withValues(alpha: opacity);
  
  /// Light theme color scheme
  static final ColorScheme lightColorScheme = ColorScheme(
    primary: primaryRed,
    secondary: primaryDark,
    surface: white,
    surfaceBright: white,
    error: const Color(0xFFB00020),
    onPrimary: white,
    onSecondary: white,
    onSurface: primaryDark,
    onSurfaceVariant: primaryDark,
    onError: white,
    brightness: Brightness.light,
  );

  /// Dark theme color scheme - uses primaryDark as the main background
  static final ColorScheme darkColorScheme = ColorScheme(
    primary: primaryRed,
    secondary: white,
    surface: primaryDark,
    surfaceBright: primaryDark,
    error: const Color(0xFFCF6679),
    onPrimary: white,
    onSecondary: primaryDark,
    onSurface: white,
    onSurfaceVariant: white,
    onError: primaryDark,
    brightness: Brightness.dark,
  );
}