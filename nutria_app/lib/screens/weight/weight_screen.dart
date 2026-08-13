import 'package:flutter/material.dart';

import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutria_app_bar.dart';
import '../../widgets/retry_state.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    final history = await NutritionRepository.instance.weightHistory();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (history == null) {
        _loadFailed = true;
      } else {
        _history = history;
      }
    });
  }

  Future<void> _addWeight() async {
    final ctrl = TextEditingController();
    final value = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nuevo registro de peso', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.numeric(size: 22),
              decoration: InputDecoration(
                suffixText: 'kg',
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
                  if (v != null) Navigator.of(context).pop(v);
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );

    if (value == null) return;
    await NutritionRepository.instance.logWeight(value);
    DiaryBus.instance.refresh();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final latest = _history.isNotEmpty ? _history.last['weight_kg'] as num : null;
    final first = _history.isNotEmpty ? _history.first['weight_kg'] as num : null;
    final delta = (latest != null && first != null) ? latest - first : null;

    return Scaffold(
      appBar: const NutriaHeader(title: 'Tu peso'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _loadFailed
          ? RetryState(onRetry: _load)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PESO ACTUAL', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 4),
                          Text(latest != null ? '${latest.toStringAsFixed(1)} kg' : '—', style: AppTypography.numeric(size: 28)),
                        ],
                      ),
                    ),
                    if (delta != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: delta <= 0 ? AppColors.goodSoft : AppColors.warnSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                          style: TextStyle(color: delta <= 0 ? AppColors.good : AppColors.warn, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_history.length >= 2)
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _WeightChartPainter(_history.map((e) => (e['weight_kg'] as num).toDouble()).toList()),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text('HISTORIAL', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                ..._history.reversed.map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${e['date']}', style: Theme.of(context).textTheme.bodyMedium),
                        Text('${(e['weight_kg'] as num).toStringAsFixed(1)} kg', style: AppTypography.numeric(size: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWeight,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxV = values.reduce((a, b) => a > b ? a : b) + 0.5;
    final range = (maxV - minV).clamp(0.1, double.infinity);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - ((values[i] - minV) / range) * size.height;
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
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

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
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

    canvas.drawCircle(points.last, 4, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) => oldDelegate.values != values;
}
