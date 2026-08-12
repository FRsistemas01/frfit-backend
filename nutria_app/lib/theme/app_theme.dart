import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final textTheme = AppTypography.textTheme(AppColors.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      fontFamily: textTheme.bodyMedium?.fontFamily,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accent,
        secondary: AppColors.accent70,
        error: AppColors.warn,
        onSurface: AppColors.textPrimary,
        onPrimary: Colors.white,
      ),
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          elevation: 10,
          shadowColor: AppColors.accent.withValues(alpha: 0.55),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }
}
