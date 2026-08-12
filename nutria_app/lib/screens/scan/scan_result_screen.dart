import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_gate.dart';

const _mealTypes = [
  (id: 'breakfast', label: 'Desayuno'),
  (id: 'lunch', label: 'Almuerzo'),
  (id: 'snack', label: 'Merienda'),
  (id: 'dinner', label: 'Cena'),
];

String _inferMealType() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'breakfast';
  if (hour < 16) return 'lunch';
  if (hour < 19) return 'snack';
  return 'dinner';
}

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key, required this.photoPath});
  final String? photoPath;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  FoodScanResult? _result;
  late String _mealType = _inferMealType();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final path = widget.photoPath;
    try {
      final result = path != null
          ? await NutritionRepository.instance.scanPhoto(File(path))
          : await NutritionRepository.instance.scanPhoto(File('mock'));
      if (!mounted) return;
      setState(() => _result = result);
    } on PremiumRequiredException catch (e) {
      if (!mounted) return;
      // Mostramos el aviso con la pantalla todavía montada y recién ahí
      // volvemos atrás — usar el context después de pop() no es seguro.
      showPremiumRequired(context, e.message);
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmAdd() async {
    final r = _result;
    if (r == null || _saving) return;
    setState(() => _saving = true);
    final ok = await NutritionRepository.instance.addScannedMeal(mealType: _mealType, items: r.items, qualityScore: r.qualityScore);
    if (ok) DiaryBus.instance.refresh();
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar — probá de nuevo.'), backgroundColor: AppColors.warnSoft),
      );
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;

    return Scaffold(
      body: r == null
          ? const _AnalyzingState()
          : Column(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.photoPath != null
                          ? Image.file(File(widget.photoPath!), fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF3A3350), Color(0xFF100D16)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              ),
                              child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 48))),
                            ),
                      Positioned(
                        top: 44,
                        left: 12,
                        child: _CircleButton(icon: Icons.close, onTap: () => Navigator.of(context).pop()),
                      ),
                      Positioned(
                        top: 44,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text(
                            '${((r.items.isNotEmpty ? (r.items.map((i) => i.confidence ?? 0.9).reduce((a, b) => a + b) / r.items.length) : 0.9) * 100).round()}% confianza',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Text('AGREGAR A', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _mealTypes
                            .map(
                              (m) => GestureDetector(
                                onTap: () => setState(() => _mealType = m.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _mealType == m.id ? AppColors.accent : AppColors.surface2,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    border: Border.all(color: _mealType == m.id ? AppColors.accent : AppColors.border),
                                  ),
                                  child: Text(m.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _mealType == m.id ? Colors.white : AppColors.textPrimary)),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...r.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: Theme.of(context).textTheme.bodyLarge),
                                    if (item.grams != null)
                                      Text('${item.grams!.round()}g', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Text('${item.kcal}', style: AppTypography.numeric(size: 14)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: AppColors.border, height: 24),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(color: AppColors.goodSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(color: AppColors.good, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(r.qualityScore.isEmpty ? 'B+' : r.qualityScore,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                r.qualityNote.isEmpty ? 'Plato balanceado' : r.qualityNote,
                                style: const TextStyle(color: AppColors.good, fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _confirmAdd,
                      child: _saving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Agregar al día · ${r.totalKcal} kcal'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AnalyzingState extends StatelessWidget {
  const _AnalyzingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: AppSpacing.md),
          Text('Analizando el plato con IA…', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
