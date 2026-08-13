import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../services/step_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/concentric_rings.dart';
import '../../widgets/glow_backdrop.dart';
import '../../widgets/nutria_route.dart';
import '../../widgets/retry_state.dart';
import '../../widgets/section_label.dart';
import '../../widgets/skeleton.dart';
import '../log_meal/log_meal_screen.dart';

const _mealIcons = {'breakfast': '🍳', 'lunch': '🍗', 'snack': '🍎', 'dinner': '🍝'};
const _mealLabels = {'breakfast': 'Desayuno', 'lunch': 'Almuerzo', 'snack': 'Merienda', 'dinner': 'Cena'};

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TodaySummary? _summary;
  bool _loadFailed = false;
  int _waterGlasses = 5;
  String _username = '';
  double? _userWeightKg;
  WeeklyTrend? _trend;
  int? _steps;
  bool _stepsAvailable = true;
  StreamSubscription<int>? _stepsSub;

  @override
  void initState() {
    super.initState();
    _load();
    _loadTrend();
    NutritionRepository.instance.getProfile().then((p) {
      if (mounted && p != null) {
        setState(() {
          _username = p.username;
          _userWeightKg = p.currentWeightKg;
        });
      }
    });
    DiaryBus.instance.addListener(_load);
    DiaryBus.instance.addListener(_loadTrend);
    _initSteps();
  }

  Future<void> _initSteps() async {
    try {
      await StepService.instance.start();
    } catch (_) {
      // start() ya deja el estado en "no disponible" ante cualquier error;
      // este catch es solo para que un fallo acá nunca cuelgue el resto de Hoy.
    }
    if (!mounted) return;
    setState(() => _stepsAvailable = StepService.instance.available);
    _stepsSub = StepService.instance.todaySteps.listen((steps) {
      if (mounted) setState(() => _steps = steps);
    });
  }

  Future<void> _loadTrend() async {
    final trend = await NutritionRepository.instance.weeklyTrend();
    if (mounted && trend != null) setState(() => _trend = trend);
  }

  @override
  void dispose() {
    DiaryBus.instance.removeListener(_load);
    DiaryBus.instance.removeListener(_loadTrend);
    _stepsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    final summary = await NutritionRepository.instance.today();
    if (!mounted) return;
    if (summary == null) {
      setState(() => _loadFailed = true);
      return;
    }
    setState(() {
      _summary = summary;
      _waterGlasses = summary.waterGlasses;
    });
  }

  Future<void> _setWater(int glasses) async {
    final clamped = glasses.clamp(0, _summary?.waterTarget ?? 8);
    setState(() => _waterGlasses = clamped);
    await NutritionRepository.instance.logWater(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    if (s == null) {
      return _loadFailed ? RetryState(onRetry: _load) : const TodaySkeleton();
    }

    final kcalProgress = s.kcalConsumed / s.kcalTarget;
    final proteinProgress = s.proteinConsumedG / s.proteinTargetG;
    final carbsProgress = s.carbsConsumedG / s.carbsTargetG;

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface2,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.accentGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.32), blurRadius: 18, offset: const Offset(0, 6))],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola', style: Theme.of(context).textTheme.bodySmall),
                        Text(_username.isNotEmpty ? _username : '…', style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text('🔥 ${s.streakDays} días', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: GlowBackdrop(
              child: ConcentricRings(
                size: 224,
                gap: 16,
                rings: [
                  RingData(progress: kcalProgress, color: AppColors.accent),
                  RingData(progress: proteinProgress, color: AppColors.accent70),
                  RingData(progress: carbsProgress, color: AppColors.accent40),
                ],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCounter(
                      value: s.kcalRemaining.abs(),
                      prefix: s.kcalRemaining < 0 ? '+' : '',
                      style: AppTypography.numeric(size: 32, color: s.kcalRemaining < 0 ? AppColors.warn : AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.kcalRemaining > 0
                          ? 'KCAL RESTANTES'
                          : s.kcalRemaining == 0
                          ? '¡OBJETIVO CUMPLIDO!'
                          : 'KCAL DE MÁS',
                      style: s.kcalRemaining < 0
                          ? const TextStyle(color: AppColors.warn, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)
                          : Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('de ${s.kcalTarget} kcal', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RingLegendDot(color: AppColors.accent, label: 'Calorías'),
              const SizedBox(width: 16),
              _RingLegendDot(color: AppColors.accent70, label: 'Proteína'),
              const SizedBox(width: 16),
              _RingLegendDot(color: AppColors.accent40, label: 'Carbos'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _QuickStat(
                    icon: '👟',
                    value: _stepsAvailable ? (_steps?.toString() ?? '…') : '—',
                    label: _stepsAvailable ? 'pasos' : 'sin sensor',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickStat(
                    icon: '🔥',
                    value: _stepsAvailable && _steps != null
                        ? '${StepService.activeKcalFromSteps(_steps!, _userWeightKg ?? 75)}'
                        : '—',
                    label: 'kcal act.',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setWater(_waterGlasses + 1),
                    onLongPress: () => _setWater(_waterGlasses - 1),
                    child: _QuickStat(icon: '💧', value: '$_waterGlasses/${s.waterTarget}', label: 'vasos', highlighted: _waterGlasses >= s.waterTarget),
                  ),
                ),
              ],
            ),
          ),
          if (_trend != null && _trend!.days.any((d) => d.kcal > 0)) ...[
            const SectionLabel('Últimos 7 días'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                child: SizedBox(height: 88, child: _WeeklyTrendChart(trend: _trend!)),
              ),
            ),
          ],
          SectionLabel(
            'Comidas de hoy',
            action: 'Agregar',
            onAction: () => Navigator.of(context).push(nutriaRoute(const LogMealScreen())),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                ...s.meals.asMap().entries.map((entry) {
                  final m = entry.value;
                  return StaggeredEntrance(
                    index: entry.key,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: Text(_mealIcons[m.mealType] ?? '🍽️', style: const TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_mealLabels[m.mealType] ?? m.mealType, style: Theme.of(context).textTheme.bodyLarge),
                                Text('${m.items.length} ítems', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Text('${m.totalKcal}', style: AppTypography.numeric(size: 14)),
                          const Text(' kcal', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }),
                if (s.meals.length < 4)
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(nutriaRoute(const LogMealScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                      ),
                      alignment: Alignment.center,
                      child: const Text('+ Agregar otra comida', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingLegendDot extends StatelessWidget {
  const _RingLegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.icon, required this.value, required this.label, this.highlighted = false});
  final String icon;
  final String value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.accentSoft : AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: highlighted ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 5),
          Text(value, style: AppTypography.numeric(size: 13)),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

const _dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

class _WeeklyTrendChart extends StatelessWidget {
  const _WeeklyTrendChart({required this.trend});
  final WeeklyTrend trend;

  @override
  Widget build(BuildContext context) {
    final maxKcal = trend.days.map((d) => d.kcal).fold<int>(trend.target, (a, b) => a > b ? a : b);
    final today = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: trend.days.map((d) {
        final isToday = d.date.year == today.year && d.date.month == today.month && d.date.day == today.day;
        final ratio = maxKcal == 0 ? 0.0 : d.kcal / maxKcal;
        final overTarget = d.kcal > trend.target;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(d.kcal > 0 ? '${d.kcal}' : '', style: const TextStyle(fontSize: 7.5, color: AppColors.textMuted)),
                const SizedBox(height: 3),
                Container(
                  height: (ratio.clamp(0.04, 1.0)) * 46,
                  decoration: BoxDecoration(
                    color: d.kcal == 0
                        ? AppColors.track
                        : overTarget
                        ? AppColors.warn
                        : (isToday ? AppColors.accent : AppColors.accent40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _dayLetters[d.date.weekday - 1],
                  style: TextStyle(fontSize: 9, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: isToday ? AppColors.accent : AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
