import 'package:flutter/material.dart';

/// Sistema de color de Nutria: negro puro con un único acento violeta,
/// usado en tres intensidades para los anillos concéntricos de progreso
/// en lugar de un color distinto por métrica.
class AppColors {
  AppColors._();

  // Fondo / superficies (dark, identidad principal de la app)
  static const Color bg = Color(0xFF050406);
  static const Color surface = Color(0xFF0E0C12);
  static const Color surface2 = Color(0xFF161320);
  static const Color surface3 = Color(0xFF1E1A2B);
  static const Color border = Color(0xFF2A2438);

  // Texto
  static const Color textPrimary = Color(0xFFF4F2F8);
  static const Color textMuted = Color(0xFF948DA3);

  // Único acento: violeta, en tres intensidades
  static const Color accent = Color(0xFF9B6BFF);
  static const Color accent70 = Color(0xB39B6BFF); // ~70% opacidad
  static const Color accent40 = Color(0x529B6BFF); // ~32% opacidad
  static const Color accentSoft = Color(0xFF1D1730);

  // Semántico (solo para estado, nunca decorativo)
  static const Color good = Color(0xFF3ECF8E);
  static const Color goodSoft = Color(0xFF122A1E);
  static const Color warn = Color(0xFFE0A851);
  static const Color warnSoft = Color(0xFF302410);

  static const Color track = Color(0xFF211C2C);

  static const List<Color> accentGradient = [accent, Color(0xFF5B3BCF)];
}
