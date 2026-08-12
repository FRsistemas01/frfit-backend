import 'package:flutter/material.dart';
import '../../widgets/nutria_route.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutria_app_bar.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/skeleton.dart';
import 'recipe_detail_screen.dart';

const _mealIcons = {'breakfast': '🍳', 'lunch': '🍗', 'snack': '🍎', 'dinner': '🍝', 'any': '🍽️'};

const _promptSuggestions = [
  'Alta en proteína con pollo',
  'Vegetariana para la cena',
  'Rápida para el desayuno',
  'Baja en carbohidratos',
];

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<SavedRecipe>? _recipes;
  final _promptCtrl = TextEditingController();
  bool _generating = false;
  SavedRecipe? _draft;
  bool _savingDraft = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recipes = await NutritionRepository.instance.recipes();
    if (!mounted) return;
    setState(() => _recipes = recipes);
  }

  Future<void> _generate([String? prompt]) async {
    final p = (prompt ?? _promptCtrl.text).trim();
    if (p.isEmpty || _generating) return;
    setState(() {
      _generating = true;
      _draft = null;
    });
    final recipe = await NutritionRepository.instance.generateRecipe(p);
    if (!mounted) return;
    setState(() {
      _generating = false;
      _draft = recipe;
    });
    if (recipe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar la receta — probá de nuevo.'), backgroundColor: AppColors.warnSoft),
      );
    }
  }

  Future<void> _saveDraft() async {
    final d = _draft;
    if (d == null || _savingDraft) return;
    setState(() => _savingDraft = true);
    SavedRecipe? saved;
    PremiumRequiredException? blocked;
    try {
      saved = await NutritionRepository.instance.saveFullRecipe(d);
    } on PremiumRequiredException catch (e) {
      blocked = e;
    }
    if (!mounted) return;
    setState(() {
      _savingDraft = false;
      if (saved != null) {
        _draft = null;
        _promptCtrl.clear();
        _recipes = [saved, ...?_recipes];
      }
    });
    if (blocked != null) showPremiumRequired(context, blocked.message);
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _recipes;
    final draft = _draft;

    return Scaffold(
      appBar: const NutriaHeader(title: 'Recetas'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.accentSoft, AppColors.surface2], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.accent),
                    const SizedBox(width: 6),
                    const Text('CREAR CON IA', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _promptCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  onSubmitted: (_) => _generate(),
                  decoration: InputDecoration(
                    hintText: 'Ej: "algo alto en proteína con pollo y batata"',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _promptSuggestions
                      .map(
                        (s) => GestureDetector(
                          onTap: () => _generate(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)),
                            child: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generating ? null : () => _generate(),
                    child: _generating
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Generar receta'),
                  ),
                ),
              ],
            ),
          ),
          if (draft != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('${draft.kcal} kcal · ${draft.ingredients.length} ingredientes', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  ...draft.ingredients.take(4).map(
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('· ${i.name}', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                  if (draft.ingredients.length > 4) Text('+ ${draft.ingredients.length - 4} más…', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _draft = null),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.textMuted, side: const BorderSide(color: AppColors.border)),
                          child: const Text('Descartar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _savingDraft ? null : _saveDraft,
                          child: _savingDraft
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Guardar receta'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('TUS RECETAS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          if (recipes == null)
            const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
          else if (recipes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Todavía no tenés recetas guardadas — generá una arriba.', style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ...recipes.asMap().entries.map(
              (entry) {
                final r = entry.value;
                return StaggeredEntrance(
                index: entry.key,
                child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () async {
                      await Navigator.of(context).push(nutriaRoute(RecipeDetailScreen(recipe: r, onDeleted: _load)));
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Text(_mealIcons[r.mealType] ?? '🍽️', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: Theme.of(context).textTheme.bodyLarge),
                                Text('${r.ingredients.length} ingredientes', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Text('${r.kcal} kcal', style: AppTypography.numeric(size: 12, color: AppColors.textMuted)),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
