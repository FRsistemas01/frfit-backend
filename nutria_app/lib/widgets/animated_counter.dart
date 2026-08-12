import 'package:flutter/material.dart';

/// Número que anima suavemente de su valor anterior al nuevo cada vez que
/// cambia — el detalle que hace que la app se sienta viva en vez de estática.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({super.key, required this.value, required this.style, this.prefix = '', this.duration = const Duration(milliseconds: 700)});

  final int value;
  final TextStyle style;
  final String prefix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) => Text('$prefix${animatedValue.round()}', style: style),
    );
  }
}
