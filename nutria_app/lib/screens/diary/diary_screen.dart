import 'package:flutter/material.dart';
import '../../widgets/nutria_route.dart';

import '../../models/models.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/edit_food_item_sheet.dart';
import '../../widgets/skeleton.dart';
import '../log_meal/log_meal_screen.dart';
import '../log_meal/manual_add_screen.dart';

const _order = ['breakfast', 'lunch', 'snack', 'dinner'];
const _labels = {'breakfast': 'Desayuno', 'lunch': 'Almuerzo', 'snack': 'Merienda', 'dinner': 'Cena'};
const _icons = {'breakfast': '🍳', 'lunch': '🍗', 'snack': '🍎', 'dinner': '🍝'};

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _selected = DateTime.now();
  List<Meal> _meals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    DiaryBus.instance.addListener(_load);
  }

  @override
  void dispose() {
    DiaryBus.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final meals = await NutritionRepository.instance.diary(_selected);
    if (!mounted) return;
    setState(() {
      _meals = meals;
      _loading = false;
    });
  }

  Future<void> _deleteItem(FoodItem item) async {
    if (item.id == null) return;
    setState(() {
      for (final m in _meals) {
        m.items.removeWhere((i) => i.id == item.id);
      }
    });
    await NutritionRepository.instance.deleteFoodItem(item.id!);
    DiaryBus.instance.refresh();
  }

  Future<void> _editItem(FoodItem item) async {
    final changed = await showEditFoodItemSheet(context, item);
    if (changed == true) {
      DiaryBus.instance.refresh();
      _load();
    }
  }

  Future<void> _addToMealType(String mealType) async {
    await Navigator.of(context).push(nutriaRoute(ManualAddScreen(initialMealType: mealType)));
    _load();
  }

  Map<String, List<Meal>> get _grouped {
    final map = <String, List<Meal>>{for (final t in _order) t: []};
    for (final m in _meals) {
      map.putIfAbsent(m.mealType, () => []).add(m);
    }
    return map;
  }

  int get _totalKcal => _meals.fold(0, (sum, m) => sum + m.totalKcal);
  double get _totalProtein => _meals.expand((m) => m.items).fold(0.0, (sum, i) => sum + i.proteinG);
  double get _totalCarbs => _meals.expand((m) => m.items).fold(0.0, (sum, i) => sum + i.carbsG);
  double get _totalFat => _meals.expand((m) => m.items).fold(0.0, (sum, i) => sum + i.fatG);

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 5 - i)));
    final grouped = _grouped;
    final hasAnyMeal = _meals.any((m) => m.items.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () async {
          await Navigator.of(context).push(nutriaRoute(const LogMealScreen()));
          _load();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Text('Diario', style: Theme.of(context).textTheme.headlineLarge),
          ),
          SizedBox(
            height: 74,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              itemCount: days.length,
              itemBuilder: (context, i) {
                final d = days[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = d);
                      _load();
                    },
                    child: SizedBox(width: 42, child: _DayChip(day: d, selected: _isSameDay(d, _selected))),
                  ),
                );
              },
            ),
          ),
          if (hasAnyMeal)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: _MacroChip(label: 'Kcal', value: '$_totalKcal', color: AppColors.accent)),
                  const SizedBox(width: 6),
                  Expanded(child: _MacroChip(label: 'Prot', value: '${_totalProtein.round()}g', color: AppColors.accent70)),
                  const SizedBox(width: 6),
                  Expanded(child: _MacroChip(label: 'Carb', value: '${_totalCarbs.round()}g', color: AppColors.accent40)),
                  const SizedBox(width: 6),
                  Expanded(child: _MacroChip(label: 'Grasa', value: '${_totalFat.round()}g', color: AppColors.textMuted)),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    children: List.generate(
                      4,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Skeleton(width: 100, height: 14), const SizedBox(height: 10), Skeleton(width: double.infinity, height: 14)],
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface2,
                    onRefresh: _load,
                    child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            children: [
                              if (!hasAnyMeal) ...[
                                const SizedBox(height: AppSpacing.lg),
                                const Icon(Icons.restaurant_outlined, color: AppColors.textMuted, size: 24),
                                const SizedBox(height: AppSpacing.sm),
                                Text('Nada cargado este día todavía.', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 2),
                                Text('Tocá el + de una comida, o el botón de abajo.', style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              ..._order.asMap().entries.map((entry) {
                              final type = entry.value;
                              final meals = grouped[type]!;
                              final kcal = meals.fold(0, (sum, m) => sum + m.totalKcal);
                              return StaggeredEntrance(
                                index: entry.key,
                                child: Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${_icons[type]} ${_labels[type]!}', style: Theme.of(context).textTheme.titleMedium),
                                        Row(
                                          children: [
                                            if (kcal > 0) Text('$kcal kcal', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () => _addToMealType(type),
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                                                child: const Icon(Icons.add, size: 15, color: AppColors.accent),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (meals.every((m) => m.items.isEmpty))
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Text('Sin registros', style: Theme.of(context).textTheme.bodySmall),
                                      ),
                                    ...meals.expand(
                                      (m) => m.items.map(
                                        (item) => Dismissible(
                                          key: ValueKey(item.id ?? item.hashCode),
                                          direction: DismissDirection.endToStart,
                                          onDismissed: (_) => _deleteItem(item),
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(right: 10),
                                            child: const Icon(Icons.delete_outline_rounded, color: AppColors.warn, size: 18),
                                          ),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _editItem(item),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 7),
                                              child: Row(
                                                children: [
                                                  Expanded(child: Text(item.name, style: Theme.of(context).textTheme.bodyMedium)),
                                                  Text('${item.kcal}', style: AppTypography.numeric(size: 12, color: AppColors.textMuted)),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.edit_outlined, size: 13, color: AppColors.textMuted),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              );
                            }),
                            ],
                          ),
                  ),
          ),
          const SizedBox(height: 96),
        ],
      ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

const _weekdayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
String _weekdayLetter(int weekday) => _weekdayLetters[weekday - 1];

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.selected});
  final DateTime day;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: selected ? AppColors.accent : AppColors.border),
      ),
      child: Column(
        children: [
          Text(_weekdayLetter(day.weekday), style: TextStyle(fontSize: 9, color: selected ? Colors.white70 : AppColors.textMuted)),
          const SizedBox(height: 2),
          Text('${day.day}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
