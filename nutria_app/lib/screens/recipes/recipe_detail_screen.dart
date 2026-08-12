import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutria_app_bar.dart';

const _mealLabels = {'breakfast': 'Desayuno', 'lunch': 'Almuerzo', 'snack': 'Merienda', 'dinner': 'Cena', 'any': 'Cuando quieras'};
const _mealIcons = {'breakfast': '🍳', 'lunch': '🍗', 'snack': '🍎', 'dinner': '🍝', 'any': '🍽️'};

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe, this.onDeleted});
  final SavedRecipe recipe;
  final VoidCallback? onDeleted;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _adding = false;
  bool _deleting = false;

  Future<void> _addToDiary() async {
    setState(() => _adding = true);
    final ok = await NutritionRepository.instance.addRecipeToDiary(widget.recipe);
    if (ok) DiaryBus.instance.refresh();
    if (!mounted) return;
    setState(() => _adding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Agregada a tu diario 🎉' : 'No se pudo agregar'), backgroundColor: ok ? AppColors.goodSoft : AppColors.warnSoft),
    );
  }

  Future<void> _delete() async {
    final id = widget.recipe.id;
    if (id == null || _deleting) return;
    setState(() => _deleting = true);
    final ok = await NutritionRepository.instance.deleteRecipe(id);
    if (!mounted) return;
    if (ok) {
      widget.onDeleted?.call();
      Navigator.of(context).pop();
    } else {
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final steps = r.instructions.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Scaffold(
      appBar: NutriaHeader(
        title: '',
        actions: [
          IconButton(
            onPressed: _deleting ? null : _delete,
            icon: _deleting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warn))
                : const Icon(Icons.delete_outline_rounded, color: AppColors.warn, size: 20),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          Row(
            children: [
              Text(_mealIcons[r.mealType] ?? '🍽️', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(child: Text(r.name, style: Theme.of(context).textTheme.headlineMedium)),
            ],
          ),
          const SizedBox(height: 4),
          Text(_mealLabels[r.mealType] ?? r.mealType, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _MacroTile(label: 'Kcal', value: '${r.kcal}', color: AppColors.accent)),
              const SizedBox(width: 6),
              Expanded(child: _MacroTile(label: 'Prot', value: '${r.proteinG.round()}g', color: AppColors.accent70)),
              const SizedBox(width: 6),
              Expanded(child: _MacroTile(label: 'Carb', value: '${r.carbsG.round()}g', color: AppColors.accent40)),
              const SizedBox(width: 6),
              Expanded(child: _MacroTile(label: 'Grasa', value: '${r.fatG.round()}g', color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('INGREDIENTES', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          ...r.ingredients.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${i.name}${i.grams != null ? ' · ${i.grams!.round()}g' : ''}', style: Theme.of(context).textTheme.bodyLarge)),
                  Text('${i.kcal} kcal', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('PREPARACIÓN', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            ...steps.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.accent, fontSize: 10.5, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value.replaceFirst(RegExp(r'^\d+[.)]\s*'), ''), style: Theme.of(context).textTheme.bodyLarge)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _adding ? null : _addToDiary,
              child: _adding
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Agregar al diario de hoy'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              Text(value, style: AppTypography.numeric(size: 12)),
            ],
          ),
          Text(label, style: const TextStyle(fontSize: 8.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
