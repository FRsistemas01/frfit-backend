import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card con efecto "glass" (blur + borde sutil) usada para insights del coach
/// y previews destacadas — el detalle premium recurrente del sistema visual.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface3.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor ?? AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}
