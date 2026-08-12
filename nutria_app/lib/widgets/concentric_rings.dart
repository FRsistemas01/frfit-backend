import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RingData {
  const RingData({required this.progress, required this.color});
  final double progress; // 0..1
  final Color color;
}

/// Anillos concéntricos estilo "activity ring" pero monocromáticos: todas las
/// métricas comparten el violeta de acento en distintas intensidades, en vez
/// de un color distinto por anillo.
class ConcentricRings extends StatelessWidget {
  const ConcentricRings({
    super.key,
    required this.rings,
    required this.size,
    this.strokeWidth = 10,
    this.gap = 12,
    this.center,
  });

  final List<RingData> rings;
  final double size;
  final double strokeWidth;
  final double gap;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < rings.length; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: rings[i].progress.clamp(0, 1)),
              duration: Duration(milliseconds: 900 + i * 150),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) => CustomPaint(
                size: Size(size - i * gap * 2, size - i * gap * 2),
                painter: _RingPainter(
                  progress: animatedProgress,
                  color: rings[i].color,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
          ?center,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.strokeWidth});

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final track = Paint()
      ..color = AppColors.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * 3.14159265 * progress.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class LinearMetricBar extends StatelessWidget {
  const LinearMetricBar({super.key, required this.progress, this.color = AppColors.accent, this.height = 5});

  final double progress;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(height: height, color: AppColors.track),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0, 1)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) => Container(
                  height: height,
                  width: constraints.maxWidth * animatedProgress,
                  color: color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
