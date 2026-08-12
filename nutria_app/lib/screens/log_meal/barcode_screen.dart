import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutria_app_bar.dart';

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

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final _codeCtrl = TextEditingController();
  FoodItem? _product;
  bool _searching = false;
  bool _saving = false;
  String _error = '';
  late String _mealType = _inferMealType();

  Future<void> _search() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || _searching) return;

    setState(() {
      _searching = true;
      _product = null;
      _error = '';
    });
    final product = await NutritionRepository.instance.barcodeLookup(code);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _product = product;
      _error = product == null ? 'No encontramos ese producto en la base de datos.' : '';
    });
  }

  Future<void> _add() async {
    final p = _product;
    if (p == null || _saving) return;
    setState(() => _saving = true);
    final ok = await NutritionRepository.instance.addMealWithItems(mealType: _mealType, items: [p], source: 'barcode');
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
    final p = _product;

    return Scaffold(
      appBar: const NutriaHeader(title: 'Código de barras'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          Text('Buscamos en una base pública de productos reales (Open Food Facts).', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ej: 7790895000860',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.accent)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _searching ? null : _search,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18)),
                  child: _searching
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('El código de barras está impreso debajo del código, en el envase del producto.', style: Theme.of(context).textTheme.bodySmall),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.warnSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text(_error, style: const TextStyle(color: AppColors.warn, fontSize: 12.5)),
            ),
          ],
          if (p != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Por cada 100g', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _NutriChip(label: 'kcal', value: '${p.kcal}'),
                      const SizedBox(width: 8),
                      _NutriChip(label: 'prot', value: '${p.proteinG.round()}g'),
                      const SizedBox(width: 8),
                      _NutriChip(label: 'carb', value: '${p.carbsG.round()}g'),
                      const SizedBox(width: 8),
                      _NutriChip(label: 'grasa', value: '${p.fatG.round()}g'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('AGREGAR A', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _add,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Agregar al día'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutriChip extends StatelessWidget {
  const _NutriChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Column(
          children: [
            Text(value, style: AppTypography.numeric(size: 13)),
            Text(label, style: const TextStyle(fontSize: 8.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
