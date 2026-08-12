import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutria_app_bar.dart';

const _mealLabels = {'breakfast': 'Desayuno', 'lunch': 'Almuerzo', 'snack': 'Merienda', 'dinner': 'Cena'};

class DescribeMealScreen extends StatefulWidget {
  const DescribeMealScreen({super.key});

  @override
  State<DescribeMealScreen> createState() => _DescribeMealScreenState();
}

class _DescribeMealScreenState extends State<DescribeMealScreen> {
  final _textCtrl = TextEditingController();
  bool _parsing = false;
  bool _saving = false;
  ParsedMeal? _result;

  Future<void> _parse() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _parsing) return;
    setState(() => _parsing = true);
    final result = await NutritionRepository.instance.parseMealText(text);
    if (!mounted) return;
    setState(() {
      _parsing = false;
      _result = result;
    });
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pude interpretarlo — probá describirlo distinto.'), backgroundColor: AppColors.warnSoft),
      );
    }
  }

  Future<void> _confirm() async {
    final r = _result;
    if (r == null || r.items.isEmpty || _saving) return;
    setState(() => _saving = true);
    final ok = await NutritionRepository.instance.addMealWithItems(mealType: r.mealTypeGuess, items: r.items, source: 'search');
    if (ok) DiaryBus.instance.refresh();
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;

    return Scaffold(
      appBar: const NutriaHeader(title: 'Contale a la IA'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Text(
                  'Escribí (o dictá con el micrófono del teclado) lo que comiste, en tus palabras.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _textCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ej: "comí dos huevos revueltos y una tostada con palta"',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                    filled: true,
                    fillColor: AppColors.surface2,
                    suffixIcon: const Padding(padding: EdgeInsets.only(right: 8, top: 8), child: Icon(Icons.mic_none_rounded, color: AppColors.textMuted, size: 18)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.accent)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _parsing ? null : _parse,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    icon: _parsing
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                        : const Icon(Icons.auto_awesome_rounded, size: 15),
                    label: Text(_parsing ? 'Interpretando…' : 'Interpretar con IA'),
                  ),
                ),
                if (r != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DETECTADO', style: Theme.of(context).textTheme.labelSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(_mealLabels[r.mealTypeGuess] ?? r.mealTypeGuess, style: const TextStyle(color: AppColors.accent, fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...r.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 9),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: Theme.of(context).textTheme.bodyMedium),
                                if (item.grams != null) Text('${item.grams!.round()}g', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Text('${item.kcal} kcal', style: AppTypography.numeric(size: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          if (r != null && r.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _confirm,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Agregar a ${_mealLabels[r.mealTypeGuess] ?? r.mealTypeGuess}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
