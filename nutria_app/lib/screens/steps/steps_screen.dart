import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/nutrition_repository.dart';
import '../../services/step_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/concentric_rings.dart';
import '../../widgets/glow_backdrop.dart';
import '../../widgets/nutria_app_bar.dart';
import '../../widgets/steps_goal_sheet.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  int? _steps;
  bool _stepsAvailable = true;
  int _goal = 8000;
  double? _userWeightKg;
  StreamSubscription<int>? _stepsSub;

  @override
  void initState() {
    super.initState();
    _stepsAvailable = StepService.instance.available;
    _steps = StepService.instance.lastValue;
    _stepsSub = StepService.instance.todaySteps.listen((steps) {
      if (mounted) setState(() => _steps = steps);
    });
    NutritionRepository.instance.getProfile().then((p) {
      if (mounted && p != null) {
        setState(() {
          _goal = p.dailyStepsGoal;
          _userWeightKg = p.currentWeightKg;
        });
      }
    });
  }

  @override
  void dispose() {
    _stepsSub?.cancel();
    super.dispose();
  }

  Future<void> _pickGoal() async {
    final goal = await showStepsGoalSheet(context, current: _goal);
    if (goal == null) return;
    setState(() => _goal = goal);
    await NutritionRepository.instance.updateStepsGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps ?? 0;
    final progress = _goal == 0 ? 0.0 : (steps / _goal).clamp(0.0, 1.0);
    final reached = steps >= _goal && _stepsAvailable;
    final activeKcal = StepService.activeKcalFromSteps(steps, _userWeightKg ?? 75);

    return Scaffold(
      appBar: const NutriaHeader(title: 'Pasos'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          children: [
            if (!_stepsAvailable)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    const Icon(Icons.sensors_off_rounded, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Tu celular no tiene sensor de pasos disponible, o no le diste permiso.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: GlowBackdrop(
                spread: reached ? 1.4 : 1.0,
                child: ConcentricRings(
                  size: 240,
                  strokeWidth: 16,
                  rings: [RingData(progress: progress, color: AppColors.accent)],
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👟', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 8),
                      AnimatedCounter(value: steps, style: AppTypography.numeric(size: 40)),
                      const SizedBox(height: 4),
                      Text('de ${_goal.toString()} pasos', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
            if (reached) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text('¡Objetivo del día alcanzado! 🎉', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _StatTile(icon: '🔥', value: '$activeKcal', label: 'kcal activas'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(icon: '🎯', value: '${(progress * 100).round()}%', label: 'del objetivo'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickGoal,
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Cambiar objetivo diario'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});
  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.numeric(size: 17)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
