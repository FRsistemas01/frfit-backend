import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala tipográfica de Nutria — fuentes bundleadas como asset (no via red)
/// para que el sistema visual se vea siempre igual, con o sin conexión:
/// Manrope para display/headlines (geométrica, con carácter, ideal para
/// números grandes), Inter para body (alta legibilidad en tamaños chicos).
class AppTypography {
  AppTypography._();

  static const _manrope = 'Manrope';
  static const _inter = 'Inter';

  static TextTheme textTheme(Color base) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _manrope,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.02,
        color: base,
      ),
      headlineLarge: TextStyle(
        fontFamily: _manrope,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: base,
      ),
      headlineMedium: TextStyle(
        fontFamily: _manrope,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: base,
      ),
      titleLarge: TextStyle(fontFamily: _manrope, fontSize: 16, fontWeight: FontWeight.w700, color: base),
      titleMedium: TextStyle(fontFamily: _manrope, fontSize: 14, fontWeight: FontWeight.w700, color: base),
      bodyLarge: TextStyle(fontFamily: _inter, fontSize: 15, color: base, height: 1.5),
      bodyMedium: TextStyle(fontFamily: _inter, fontSize: 13, color: base, height: 1.5),
      bodySmall: TextStyle(fontFamily: _inter, fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
      labelLarge: TextStyle(fontFamily: _inter, fontSize: 12, fontWeight: FontWeight.w700, color: base),
      labelSmall: TextStyle(
        fontFamily: _inter,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textMuted,
      ),
    );
  }

  /// Estilo para valores numéricos grandes (kcal, macros): tabular y con tracking negativo.
  static TextStyle numeric({required double size, FontWeight weight = FontWeight.w800, Color? color}) {
    return TextStyle(
      fontFamily: _manrope,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: -0.5,
      color: color ?? AppColors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
