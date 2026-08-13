import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado de "no se pudo cargar" con botón para reintentar — para no dejar
/// una pantalla colgada en su loading para siempre cuando falla la request
/// (sesión vencida, sin internet, servidor caído).
class RetryState extends StatelessWidget {
  const RetryState({super.key, required this.onRetry, this.message = 'No se pudo cargar. Revisá tu conexión.'});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 34, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4)),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
