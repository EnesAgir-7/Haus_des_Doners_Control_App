/// This file contains the color constants used throughout the application.
/// All colors are defined as static constants for consistent usage.

import 'package:flutter/material.dart';

/// A utility class that holds all color-related constants and schemes
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  /// Primary Colors
  static const Color primaryDark = Color(0xFF1C1818);    
  static const Color primaryRed = Color(0xFFC2292B);     
  static const Color green = Colors.green;     
  static const Color lightRed = Color(0xff362424);    
  static const Color white = Color(0xFFFFFFFF);        
  static const Color lightBlack = Color(0xFF1A1A1A);          
  static const Color lightGrey = Color(0xFFC2C0B6);     
  static const Color amber = Colors.amber;         
  static const Color alertColor = Color(0xFFFF0000);         
  static const Color greyCardColor = Color(0xFF3A3A3A);       
  static const Color primaryBlue = Colors.blueAccent;
  static const Color darkGrey = Color(0xFF48484A);
  static const Color shimmerBase = Color(0xFF3A3A3C);
  static const Color shimmerHighlight = Color(0xFF48484A);  

  /// Utility methods for color opacity variations
  static Color redWithOpacity(double opacity) => primaryRed.withValues(alpha:  opacity);
  static Color darkWithOpacity(double opacity) => primaryDark.withValues(alpha: opacity);
  static Color whiteWithOpacity(double opacity) => white.withValues(alpha: opacity);
  
  /// Light theme color scheme
  static final ColorScheme lightColorScheme = const ColorScheme(
    primary: primaryRed,
    secondary: primaryDark,
    surface: white,
    surfaceBright: white,
    error: Color(0xFFB00020),
    onPrimary: white,
    onSecondary: white,
    onSurface: primaryDark,
    onSurfaceVariant: primaryDark,
    onError: white,
    brightness: Brightness.light,
  );

  /// Dark theme color scheme - uses primaryDark as the main background
  static final ColorScheme darkColorScheme = const ColorScheme(
    primary: primaryRed,
    secondary: white,
    surface: primaryDark,
    surfaceBright: primaryDark,
    error: Color(0xFFCF6679),
    onPrimary: white,
    onSecondary: primaryDark,
    onSurface: white,
    onSurfaceVariant: white,
    onError: primaryDark,
    brightness: Brightness.dark,
  );
}