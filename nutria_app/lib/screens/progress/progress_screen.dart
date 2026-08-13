import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/glow_backdrop.dart';
import '../../widgets/retry_state.dart';
import '../../widgets/skeleton.dart';

const _weekdayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressOverview? _data;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    final data = await NutritionRepository.instance.progressOverview();
    if (!mounted) return;
    if (data == null) {
      setState(() => _loadFailed = true);
      return;
    }
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Text('Progreso', style: Theme.of(context).textTheme.headlineLarge),
          ),
          Expanded(
            child: d == null
                ? (_loadFailed ? RetryState(onRetry: _load) : const _ProgressSkeleton())
                : RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface2,
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                      children: [
                        _GoalHero(data: d),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(child: _StatCard(value: d.streakDays, label: 'Racha\nactual', icon: '🔥')),
                            const SizedBox(width: 8),
                            Expanded(child: _StatCard(value: d.adherencePct30, suffix: '%', label: 'En objetivo\n30 días', icon: '🎯')),
                            const SizedBox(width: 8),
                            Expanded(child: _StatCard(value: d.avgKcal30, label: 'Prom. kcal\npor día', icon: '📊')),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text('LOGROS', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: d.badges.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) => _BadgeChip(badge: d.badges[i]),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (d.weights.length >= 2) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('EVOLUCIÓN DE PESO', style: Theme.of(context).textTheme.labelSmall),
                              Text('${d.currentWeightKg?.toStringAsFixed(1) ?? '—'} kg actual', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.surface3, AppColors.surface2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: SizedBox(
                              height: 120,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, t, _) => CustomPaint(size: Size.infinite, painter: _WeightPainter(d.weights, t)),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ÚLTIMOS 30 DÍAS', style: Theme.of(context).textTheme.labelSmall),
                            Text('${d.loggedDays30} días registrados', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                          child: _CalendarGrid(days: d.calendar),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            _LegendDot(color: AppColors.accent, label: 'En objetivo'),
                            const SizedBox(width: 14),
                            _LegendDot(color: AppColors.warn, label: 'Te pasaste'),
                            const SizedBox(width: 14),
                            _LegendDot(color: AppColors.track, label: 'Sin registro'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                          child: Row(
                            children: [
                              const Icon(Icons.insights_rounded, color: AppColors.accent, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  d.loggedDays30 == 0
                                      ? 'Todavía no hay suficientes datos — empezá a registrar tus comidas para ver tu progreso acá.'
                                      : 'Promediaste ${d.avgKcal30} kcal/día en los últimos 30 días, con ${d.onTrackDays30} días dentro de tu objetivo.',
                                  style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GoalHero extends StatelessWidget {
  const _GoalHero({required this.data});
  final ProgressOverview data;

  @override
  Widget build(BuildContext context) {
    final current = data.currentWeightKg;
    final target = data.targetWeightKg;
    final start = data.weights.isNotEmpty ? data.weights.first.weightKg : current;

    if (current == null || target == null || start == null) {
      // Sin objetivo de peso cargado: heroe con la racha, invitando a configurarlo.
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1D1730), Color(0xFF14101F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            GlowBackdrop(
              spread: 0.9,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.accentGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🔥', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedCounter(value: data.streakDays, style: AppTypography.numeric(size: 26)),
                      const SizedBox(width: 6),
                      Text(data.streakDays == 1 ? 'día seguido' : 'días seguidos', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Definí un peso objetivo en tu perfil para ver acá tu proyección real.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final totalSpan = (start - target).abs();
    final progressed = (start - current).abs();
    final progress = totalSpan == 0 ? 1.0 : (progressed / totalSpan).clamp(0.0, 1.0);
    final remaining = (current - target).abs();
    final reached = remaining < 0.3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1D1730), Color(0xFF14101F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reached ? '¡OBJETIVO ALCANZADO!' : 'CAMINO A TU OBJETIVO', style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(current.toStringAsFixed(1), style: AppTypography.numeric(size: 34)),
              const Text(' kg', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              const Spacer(),
              if (!reached)
                Text('faltan ${remaining.toStringAsFixed(1)} kg', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(height: 10, color: AppColors.track),
                    Container(
                      height: 10,
                      width: constraints.maxWidth * t,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.accentGradient),
                        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 8)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${start.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('${target.toStringAsFixed(1)} kg objetivo', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          if (data.projectedDate != null && !reached) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'A tu ritmo actual (${data.kgPerWeek?.toStringAsFixed(1)} kg/semana), lo lográs el ${_fmtDate(data.projectedDate!)}.',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${d.day} de ${months[d.month - 1]}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.icon, this.suffix = ''});
  final int value;
  final String label;
  final String icon;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedCounter(value: value, style: AppTypography.numeric(size: 16)),
              if (suffix.isNotEmpty) Text(suffix, style: AppTypography.numeric(size: 16)),
            ],
          ),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, color: AppColors.textMuted, height: 1.3)),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});
  final Achievement badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: badge.achieved ? AppColors.accentSoft : AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: badge.achieved ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: badge.achieved ? 1 : 0.35,
            child: Text(badge.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 6),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: badge.achieved ? AppColors.accent : AppColors.textMuted, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.days});
  final List<CalendarDay> days;

  Color _colorFor(String status) {
    switch (status) {
      case 'on_track':
        return AppColors.accent;
      case 'off_track':
        return AppColors.warn;
      case 'future':
        return AppColors.surface3;
      default:
        return AppColors.track;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Alinear el primer día a la columna de su día de semana real (L=0..D=6).
    final leadingBlanks = days.isEmpty ? 0 : days.first.date.weekday - 1;
    final cells = <Widget>[
      for (final letter in _weekdayLetters)
        SizedBox(width: 22, child: Center(child: Text(letter, style: const TextStyle(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.w700)))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: cells),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < leadingBlanks; i++) const SizedBox(width: 22, height: 22),
            ...days.asMap().entries.map(
              (entry) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 250 + (entry.key * 12).clamp(0, 500)),
                curve: Curves.easeOut,
                builder: (context, t, _) => Opacity(
                  opacity: t,
                  child: Tooltip(
                    message: '${entry.value.date.day}/${entry.value.date.month}${entry.value.kcal > 0 ? ' · ${entry.value.kcal} kcal' : ''}',
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: _colorFor(entry.value.status), borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeightPainter extends CustomPainter {
  _WeightPainter(this.points, this.progress);
  final List<({DateTime date, double weightKg})> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.weightKg).toList();
    final minV = values.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxV = values.reduce((a, b) => a > b ? a : b) + 0.5;
    final range = (maxV - minV).clamp(0.1, double.infinity);

    final allOffsets = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - ((values[i] - minV) / range) * size.height;
      allOffsets.add(Offset(x, y));
    }

    final visibleCount = (allOffsets.length * progress).ceil().clamp(2, allOffsets.length);
    final offsets = allOffsets.sublist(0, visibleCount);

    final fillPath = Path()..moveTo(offsets.first.dx, size.height);
    for (final p in offsets) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.accent.withValues(alpha: 0.28), AppColors.accent.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final p in offsets.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(offsets.last, 4, Paint()..color = AppColors.accent);
    canvas.drawCircle(offsets.last, 4, Paint()..color = AppColors.accent.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(covariant _WeightPainter oldDelegate) => oldDelegate.points != points || oldDelegate.progress != progress;
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Skeleton(width: double.infinity, height: 130, radius: 20),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: Skeleton(height: 76, radius: 14)), const SizedBox(width: 8), Expanded(child: Skeleton(height: 76, radius: 14)), const SizedBox(width: 8), Expanded(child: Skeleton(height: 76, radius: 14))]),
          const SizedBox(height: 24),
          Skeleton(width: double.infinity, height: 110, radius: 14),
          const SizedBox(height: 24),
          Skeleton(width: double.infinity, height: 150, radius: 14),
        ],
      ),
    );
  }
}
