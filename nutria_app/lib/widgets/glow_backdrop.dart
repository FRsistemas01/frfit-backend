import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Glow radial que se funde a alpha 0 sin bordes duros — el detalle premium
/// del sistema visual detrás de los elementos "hero" (anillos, marcas).
class GlowBackdrop extends StatelessWidget {
  const GlowBackdrop({super.key, required this.child, this.color = AppColors.accent, this.spread = 1.5});

  final Widget child;
  final Color color;
  final double spread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Container(
            width: 260 * spread,
            height: 260 * spread,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
                stops: const [0, 0.72],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
