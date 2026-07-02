import 'package:flutter/material.dart';

/// Central dark palette + [ThemeData] for the Discipline tracker.
///
/// Colors are pulled straight from the reference mockups: a near-black
/// background, slightly lighter cards, a fiery orange accent for streaks, and
/// green/red for win/loss outcomes.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0F14);
  static const Color card = Color(0xFF161B22);
  static const Color cardBorder = Color(0xFF232A33);

  static const Color fire = Color(0xFFFF7A1A); // streak / accent orange
  static const Color win = Color(0xFF22C55E); // green
  static const Color loss = Color(0xFFEF4444); // red

  static const Color textPrimary = Color(0xFFF2F5F8);
  static const Color textSecondary = Color(0xFF8B95A1);
}

/// Builds the app-wide dark [ThemeData].
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const base = ColorScheme.dark(
      primary: AppColors.fire,
      surface: AppColors.card,
      onSurface: AppColors.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base,
      fontFamily: 'SF Pro Text',
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
