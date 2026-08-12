import 'package:flutter/material.dart';
import '../../widgets/nutria_route.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/models.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutria_app_bar.dart';
import '../scan/scan_result_screen.dart';
import '../recipes/recipe_detail_screen.dart';
import '../recipes/recipes_screen.dart';
import 'barcode_screen.dart';
import 'describe_meal_screen.dart';
import 'manual_add_screen.dart';

String _inferMealType() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'breakfast';
  if (hour < 16) return 'lunch';
  if (hour < 19) return 'snack';
  return 'dinner';
}

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  List<SavedRecipe>? _recipes;
  List<FrequentFood>? _frequent;
  String? _adding;

  @override
  void initState() {
    super.initState();
    NutritionRepository.instance.recipes().then((r) {
      if (mounted) setState(() => _recipes = r);
    });
    NutritionRepository.instance.frequentFoods().then((f) {
      if (mounted) setState(() => _frequent = f);
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo == null) {
      if (!mounted) return;
      Navigator.of(context).push(nutriaRoute(ScanResultScreen(photoPath: null)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(nutriaRoute(ScanResultScreen(photoPath: photo.path)));
  }

  Future<void> _quickAddFrequent(FrequentFood f) async {
    setState(() => _adding = 'freq-${f.name}');
    final item = FoodItem(name: f.name, grams: f.avgGrams, kcal: f.avgKcal, proteinG: f.avgProtein, carbsG: f.avgCarbs, fatG: f.avgFat);
    final ok = await NutritionRepository.instance.addMealWithItems(mealType: _inferMealType(), items: [item]);
    if (ok) DiaryBus.instance.refresh();
    if (!mounted) return;
    setState(() => _adding = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '${f.name} agregado 👍' : 'No se pudo agregar'), backgroundColor: ok ? AppColors.goodSoft : AppColors.warnSoft),
    );
  }

  Future<void> _openRecipe(SavedRecipe r) async {
    await Navigator.of(context).push(nutriaRoute(RecipeDetailScreen(recipe: r)));
    final recipes = await NutritionRepository.instance.recipes();
    if (mounted) setState(() => _recipes = recipes);
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _recipes;
    final frequent = _frequent;

    return Scaffold(
      appBar: const NutriaHeader(title: 'Agregar comida'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.4,
            children: [
              _MethodTile(icon: '📷', label: 'Foto con IA', primary: true, onTap: _pickPhoto),
              _MethodTile(
                icon: '📊',
                label: 'Código de barras',
                onTap: () => Navigator.of(context).push(nutriaRoute(const BarcodeScreen())),
              ),
              _MethodTile(
                icon: '🔍',
                label: 'Buscar',
                onTap: () => Navigator.of(context).push(nutriaRoute(const ManualAddScreen())),
              ),
              _MethodTile(
                icon: '🎙️',
                label: 'Contale a la IA',
                onTap: () => Navigator.of(context).push(nutriaRoute(const DescribeMealScreen())),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MIS RECETAS', style: Theme.of(context).textTheme.labelSmall),
              GestureDetector(
                onTap: () => Navigator.of(context).push(nutriaRoute(const RecipesScreen())),
                child: const Text('Ver todas / crear con IA', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (recipes == null)
            const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)))
          else if (recipes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Todavía no tenés recetas — creá una con IA desde "Ver todas".', style: Theme.of(context).textTheme.bodySmall),
            )
          else
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recipes.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final r = recipes[i];
                  return GestureDetector(
                    onTap: () => _openRecipe(r),
                    child: Container(
                      width: 108,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.surface3, AppColors.surface2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.bookmark_rounded, size: 12, color: AppColors.accent),
                          const Spacer(),
                          Text(r.name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text('${r.kcal} kcal', style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('FRECUENTES', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          if (frequent == null)
            const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)))
          else if (frequent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('A medida que cargues comidas, las más repetidas van a aparecer acá para sumarlas de un toque.', style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ...frequent.map((f) {
              final adding = _adding == 'freq-${f.name}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: GestureDetector(
                  onTap: adding ? null : () => _quickAddFrequent(f),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(9)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.restaurant, size: 14, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(f.name, style: Theme.of(context).textTheme.bodyLarge)),
                      Text('${f.avgKcal}', style: AppTypography.numeric(size: 12, color: AppColors.textMuted)),
                      const SizedBox(width: AppSpacing.sm),
                      if (adding)
                        const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                      else
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                          child: const Icon(Icons.add, size: 14, color: AppColors.accent),
                        ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.icon, required this.label, this.primary = false, required this.onTap});
  final String icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: primary ? const LinearGradient(colors: AppColors.accentGradient, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            color: primary ? null : AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: primary ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: primary ? Colors.white : AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
