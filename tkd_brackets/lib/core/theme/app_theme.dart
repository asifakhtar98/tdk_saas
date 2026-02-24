import 'package:flutter/material.dart';

/// TKD Brackets theme configuration using Material Design 3.
///
/// Brand Colors:
/// - Primary: Navy (#1E3A5F) - Trust, professionalism
/// - Secondary: Gold (#D4AF37) - Excellence, achievement
class AppTheme {
  AppTheme._();

  static const _navyPrimary = Color(0xFF1E3A5F);
  static const _goldSecondary = Color(0xFFD4AF37);

  /// Light theme configuration.
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _navyPrimary,
      secondary: _goldSecondary,
    ),
  );

  /// Dark theme configuration.
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _navyPrimary,
      secondary: _goldSecondary,
      brightness: Brightness.dark,
    ),
  );
}
