/// This file contains the theme configurations for both light and dark modes.
/// It defines the visual properties for various Material widgets.

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

/// A utility class that provides theme data for the application
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Default border radius used throughout the app
  static final _defaultBorderRadius = BorderRadius.circular(8);

  /// Light theme configuration
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightColorScheme,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: kAppFont,

      // AppBar teması
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),

      // Buton teması
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: _defaultBorderRadius),
        ),
      ),

      // FloatingActionButton teması
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.white,
      ),

      // IconButton teması
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.primaryDark),
      ),

      // Card teması
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: _defaultBorderRadius),
      ),

      // Input Decoration teması
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: const BorderSide(color: AppColors.primaryDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: const BorderSide(color: AppColors.primaryRed),
        ),
      ),
    );
  }

  /// Dark theme configuration
  /// Uses primaryDark as the main background color and adjusts all components accordingly
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.darkColorScheme,
      scaffoldBackgroundColor: AppColors.primaryDark,
      fontFamily: kAppFont,

      // AppBar teması
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),

      // Buton teması
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: _defaultBorderRadius),
        ),
      ),

      // FloatingActionButton teması
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.white,
      ),

      // IconButton teması
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.white),
      ),

      // Card teması
      cardTheme: CardThemeData(
        color: AppColors.primaryDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: _defaultBorderRadius),
      ),

      // Input Decoration teması
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primaryDark,
        border: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: const BorderSide(color: AppColors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: const BorderSide(color: AppColors.primaryRed),
        ),
        labelStyle: const TextStyle(color: AppColors.white),
        hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.7)),
      ),
    );
  }
}
