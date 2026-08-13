import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/concentric_rings.dart';
import '../../widgets/glow_backdrop.dart';
import '../../widgets/nutria_app_bar.dart';
import '../../widgets/retry_state.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  FastingState? _state;
  bool _loadFailed = false;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    final state = await NutritionRepository.instance.fastingState();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loadFailed = state == null;
    });
    _tick();
  }

  void _tick() {
    final active = _state?.active;
    if (active == null || !mounted) return;
    setState(() => _elapsed = DateTime.now().difference(active.startedAt));
  }

  Future<void> _startFasting() async {
    setState(() => _busy = true);
    await NutritionRepository.instance.startFasting();
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _endFasting() async {
    setState(() => _busy = true);
    await NutritionRepository.instance.endFasting();
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      return _loadFailed ? RetryState(onRetry: _load) : const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final active = state.active;
    final targetHours = active?.targetHours ?? 16;
    final progress = active == null ? 0.0 : _elapsed.inMinutes / (targetHours * 60);
    final completedRecently = state.history.where((s) => s.completed).length;

    return Scaffold(
      appBar: const NutriaHeader(title: 'Ayuno intermitente'),
      body: RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface2,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Ventana $targetHours:${24 - targetHours}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: GlowBackdrop(
              color: active == null ? AppColors.textMuted : AppColors.accent,
              child: ConcentricRings(
                size: 250,
                rings: [RingData(progress: active == null ? 0 : progress, color: AppColors.accent)],
                strokeWidth: 13,
                center: active == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.nightlight_round, color: AppColors.textMuted, size: 26),
                          const SizedBox(height: 8),
                          Text('SIN AYUNO ACTIVO', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_fmtDuration(_elapsed), style: AppTypography.numeric(size: 26)),
                          const SizedBox(height: 4),
                          Text(
                            progress >= 1 ? '¡OBJETIVO CUMPLIDO!' : 'EN AYUNO',
                            style: TextStyle(color: progress >= 1 ? AppColors.good : AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (active != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimeStat(label: 'Inicio', value: _fmtClock(active.startedAt)),
                Container(width: 1, height: 30, color: AppColors.border),
                _TimeStat(label: 'Rompe ayuno', value: _fmtClock(active.startedAt.add(Duration(hours: targetHours)))),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : (active == null ? _startFasting : _endFasting),
              style: active != null
                  ? ElevatedButton.styleFrom(backgroundColor: AppColors.surface2, foregroundColor: AppColors.warn, elevation: 0, shadowColor: Colors.transparent)
                  : null,
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(active == null ? 'Empezar ayuno' : 'Romper ayuno ahora'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    active == null
                        ? 'Tu último ayuno fue hace un tiempo. Empezá cuando termines de comer por hoy.'
                        : progress < 0.5
                        ? 'Recién arrancás — tu cuerpo todavía está usando la energía de tu última comida.'
                        : progress < 1
                        ? 'Ya pasaste la mitad — el cuerpo empieza a usar más grasa como energía.'
                        : 'Completaste tu ventana de ayuno. Podés romperlo cuando quieras.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ÚLTIMOS AYUNOS', style: Theme.of(context).textTheme.labelSmall),
              Text('$completedRecently completados', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text('Todavía no completaste ningún ayuno.', style: Theme.of(context).textTheme.bodySmall),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: state.history
                  .map(
                    (s) => Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: s.completed ? AppColors.accent : AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: s.completed ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 10)] : null,
                      ),
                      child: s.completed ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
      ),
    );
  }

  String _fmtDuration(Duration d) => '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
  String _fmtClock(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _TimeStat extends StatelessWidget {
  const _TimeStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.numeric(size: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}
