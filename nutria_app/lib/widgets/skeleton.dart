import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder con brillo animado en vez de un spinner genérico — se usa
/// mientras carga contenido cuya forma ya conocemos (una card, una línea).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: [AppColors.surface2, AppColors.surface3, AppColors.surface2],
              stops: [(t - 0.3).clamp(0, 1), t, (t + 0.3).clamp(0, 1)],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder de la pantalla Hoy mientras carga: silueta del anillo + stats,
/// para que la carga inicial no sea una pantalla negra con un spinner solo.
class TodaySkeleton extends StatelessWidget {
  const TodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Row(children: [Skeleton(width: 42, height: 42, radius: 13), const SizedBox(width: 12), Skeleton(width: 100, height: 18)]),
          const SizedBox(height: 40),
          Center(child: Skeleton(width: 200, height: 200, radius: 100)),
          const SizedBox(height: 40),
          Row(children: [Expanded(child: Skeleton(height: 60, radius: 14)), const SizedBox(width: 8), Expanded(child: Skeleton(height: 60, radius: 14)), const SizedBox(width: 8), Expanded(child: Skeleton(height: 60, radius: 14))]),
        ],
      ),
    );
  }
}

/// Envuelve una lista para que cada ítem aparezca escalonado (fade + slide)
/// en vez de aparecer todos de golpe — le da sensación de "vivo" a la carga.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 60).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
        );
      },
    );
  }
}
