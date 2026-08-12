import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutria_app_bar.dart';
import '../../widgets/premium_gate.dart';

const _mealTypes = [
  (id: 'breakfast', label: 'Desayuno'),
  (id: 'lunch', label: 'Almuerzo'),
  (id: 'snack', label: 'Merienda'),
  (id: 'dinner', label: 'Cena'),
];

class ManualAddScreen extends StatefulWidget {
  const ManualAddScreen({super.key, this.initialMealType});
  final String? initialMealType;

  @override
  State<ManualAddScreen> createState() => _ManualAddScreenState();
}

class _ManualAddScreenState extends State<ManualAddScreen> {
  late String _mealType = widget.initialMealType ?? 'lunch';
  final _nameCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController(text: '100');
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  final List<FoodItem> _cart = [];
  bool _estimating = false;
  bool _saving = false;
  bool _hasEstimate = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gramsCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _estimate() async {
    final name = _nameCtrl.text.trim();
    final grams = double.tryParse(_gramsCtrl.text) ?? 100;
    if (name.isEmpty || _estimating) return;

    setState(() => _estimating = true);
    final item = await NutritionRepository.instance.lookupFood(name, grams);
    if (!mounted) return;
    setState(() {
      _estimating = false;
      if (item != null) {
        _kcalCtrl.text = item.kcal.toString();
        _proteinCtrl.text = item.proteinG.round().toString();
        _carbsCtrl.text = item.carbsG.round().toString();
        _fatCtrl.text = item.fatG.round().toString();
        _hasEstimate = true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pude estimarlo — completá los valores a mano.'), backgroundColor: AppColors.warnSoft),
        );
      }
    });
  }

  bool _pushDraftToCart() {
    final name = _nameCtrl.text.trim();
    final kcal = int.tryParse(_kcalCtrl.text);
    if (name.isEmpty || kcal == null) return false;

    setState(() {
      _cart.add(
        FoodItem(
          name: name,
          grams: double.tryParse(_gramsCtrl.text),
          kcal: kcal,
          proteinG: double.tryParse(_proteinCtrl.text) ?? 0,
          carbsG: double.tryParse(_carbsCtrl.text) ?? 0,
          fatG: double.tryParse(_fatCtrl.text) ?? 0,
        ),
      );
      _nameCtrl.clear();
      _gramsCtrl.text = '100';
      _kcalCtrl.clear();
      _proteinCtrl.clear();
      _carbsCtrl.clear();
      _fatCtrl.clear();
      _hasEstimate = false;
    });
    return true;
  }

  Future<void> _saveMeal() async {
    if (_nameCtrl.text.trim().isNotEmpty) _pushDraftToCart();
    if (_cart.isEmpty || _saving) return;

    setState(() => _saving = true);
    final ok = await NutritionRepository.instance.addMealWithItems(mealType: _mealType, items: _cart);
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

  Future<void> _saveAsRecipe(FoodItem item) async {
    bool ok;
    try {
      ok = await NutritionRepository.instance.saveRecipe(name: item.name, kcal: item.kcal, proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG);
    } on PremiumRequiredException catch (e) {
      if (!mounted) return;
      showPremiumRequired(context, e.message);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '"${item.name}" guardada como receta' : 'No se pudo guardar la receta'), backgroundColor: ok ? AppColors.goodSoft : AppColors.warnSoft),
    );
  }

  int get _cartKcal => _cart.fold(0, (sum, i) => sum + i.kcal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NutriaHeader(title: 'Agregar comida'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Text('COMIDA', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
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
                if (_cart.isNotEmpty) ...[
                  Text('EN ESTA COMIDA · $_cartKcal kcal', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.sm),
                  ..._cart.asMap().entries.map(
                    (e) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 9),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.value.name, style: Theme.of(context).textTheme.bodyMedium)),
                          Text('${e.value.kcal}', style: AppTypography.numeric(size: 12, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _saveAsRecipe(e.value),
                            child: const Icon(Icons.bookmark_add_outlined, size: 17, color: AppColors.accent),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => setState(() => _cart.removeAt(e.key)),
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: AppColors.border, height: 24),
                ],
                Text('AGREGAR ÍTEM', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _Field(label: 'Alimento', controller: _nameCtrl)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(flex: 2, child: _Field(label: 'Gramos', controller: _gramsCtrl, numeric: true)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _estimating ? null : _estimate,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    icon: _estimating
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                        : const Icon(Icons.auto_awesome_rounded, size: 15),
                    label: Text(_estimating ? 'Estimando…' : 'Estimar kcal y macros con IA'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_hasEstimate)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.good),
                        const SizedBox(width: 4),
                        Text('Estimado por IA — podés ajustarlo', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                _Field(label: 'Calorías (kcal)', controller: _kcalCtrl, numeric: true),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _Field(label: 'Prot (g)', controller: _proteinCtrl, numeric: true)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _Field(label: 'Carb (g)', controller: _carbsCtrl, numeric: true)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _Field(label: 'Grasa (g)', controller: _fatCtrl, numeric: true)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _pushDraftToCart,
                    icon: const Icon(Icons.add, size: 16, color: AppColors.accent),
                    label: const Text('Agregar otro ítem a esta comida', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveMeal,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_cart.isEmpty ? 'Guardar comida' : 'Guardar comida · $_cartKcal kcal'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, this.numeric = false});
  final String label;
  final TextEditingController controller;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.accent)),
      ),
    );
  }
}
