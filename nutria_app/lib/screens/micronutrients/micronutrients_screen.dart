import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/concentric_rings.dart';
import '../../widgets/nutria_app_bar.dart';

class MicronutrientsScreen extends StatefulWidget {
  const MicronutrientsScreen({super.key});

  @override
  State<MicronutrientsScreen> createState() => _MicronutrientsScreenState();
}

class _MicronutrientsScreenState extends State<MicronutrientsScreen> {
  Micronutrients? _data;

  @override
  void initState() {
    super.initState();
    NutritionRepository.instance.micronutrients().then((m) {
      if (mounted) setState(() => _data = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _data;
    if (m == null) return const Center(child: CircularProgressIndicator(color: AppColors.accent));

    final rows = [
      (label: 'Fibra', value: m.fiberG, target: 30, unit: 'g', warn: false),
      (label: 'Hierro', value: m.ironMg, target: 18, unit: 'mg', warn: false),
      (label: 'Calcio', value: m.calciumMg, target: 1000, unit: 'mg', warn: false),
      (label: 'Vitamina C', value: m.vitaminCMg, target: 90, unit: 'mg', warn: false),
      (label: 'Vitamina D', value: m.vitaminDUg, target: 15, unit: 'µg', warn: false),
      (label: 'Sodio', value: m.sodiumMg, target: 2300, unit: 'mg', warn: m.sodiumMg > 2300),
    ];

    final allZero = rows.every((r) => r.value == 0);

    return Scaffold(
      appBar: const NutriaHeader(title: 'Micronutrientes'),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface2,
        onRefresh: () async {
          final data = await NutritionRepository.instance.micronutrients();
          if (mounted) setState(() => _data = data);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          children: [
            Text('Más allá de las calorías — vitaminas y minerales de hoy.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.label, style: TextStyle(color: r.warn ? AppColors.warn : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                          '${r.value.round()}/${r.target}${r.unit}',
                          style: AppTypography.numeric(size: 12.5, color: r.warn ? AppColors.warn : AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearMetricBar(progress: r.value / r.target, color: r.warn ? AppColors.warn : AppColors.accent, height: 6),
                  ],
                ),
              ),
            ),
            if (allZero)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                child: Text(
                  'Todavía no cargaste comidas hoy — a medida que registrés, esto se va a ir completando solo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
