import 'package:flutter/material.dart';

import '../screens/premium/premium_screen.dart';
import '../theme/app_theme.dart';
import 'nutria_route.dart';

/// Aviso consistente para cuando el backend devuelve 402 (límite del plan
/// free): un snackbar con acción directa a la pantalla de Premium, en vez de
/// un error genérico.
void showPremiumRequired(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface2,
        content: Text(message, style: const TextStyle(color: AppColors.textPrimary)),
        action: SnackBarAction(
          label: 'Ver Premium',
          textColor: AppColors.accent,
          onPressed: () => Navigator.of(context).push(nutriaRoute(const PremiumScreen())),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
}
