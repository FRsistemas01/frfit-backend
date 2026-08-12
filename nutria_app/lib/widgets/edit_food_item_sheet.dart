import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/nutrition_repository.dart';
import '../theme/app_theme.dart';

/// Bottom sheet para editar un ítem de comida ya cargado. Devuelve `true`
/// por el Navigator si se guardó un cambio, para que quien la abrió refresque.
Future<bool?> showEditFoodItemSheet(BuildContext context, FoodItem item) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (context) => _EditFoodItemSheet(item: item),
  );
}

class _EditFoodItemSheet extends StatefulWidget {
  const _EditFoodItemSheet({required this.item});
  final FoodItem item;

  @override
  State<_EditFoodItemSheet> createState() => _EditFoodItemSheetState();
}

class _EditFoodItemSheetState extends State<_EditFoodItemSheet> {
  late final _nameCtrl = TextEditingController(text: widget.item.name);
  late final _gramsCtrl = TextEditingController(text: widget.item.grams?.round().toString() ?? '');
  late final _kcalCtrl = TextEditingController(text: widget.item.kcal.toString());
  late final _proteinCtrl = TextEditingController(text: widget.item.proteinG.round().toString());
  late final _carbsCtrl = TextEditingController(text: widget.item.carbsG.round().toString());
  late final _fatCtrl = TextEditingController(text: widget.item.fatG.round().toString());
  bool _saving = false;
  bool _deleting = false;

  Future<void> _delete() async {
    final id = widget.item.id;
    if (id == null || _deleting || _saving) return;
    setState(() => _deleting = true);
    final ok = await NutritionRepository.instance.deleteFoodItem(id);
    if (!mounted) return;
    if (!ok) {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo borrar.'), backgroundColor: AppColors.warnSoft),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _save() async {
    final id = widget.item.id;
    final kcal = int.tryParse(_kcalCtrl.text);
    if (id == null || _nameCtrl.text.trim().isEmpty || kcal == null || _saving) return;

    setState(() => _saving = true);
    final ok = await NutritionRepository.instance.updateFoodItem(
      id,
      name: _nameCtrl.text.trim(),
      grams: double.tryParse(_gramsCtrl.text),
      kcal: kcal,
      proteinG: double.tryParse(_proteinCtrl.text) ?? 0,
      carbsG: double.tryParse(_carbsCtrl.text) ?? 0,
      fatG: double.tryParse(_fatCtrl.text) ?? 0,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el cambio.'), backgroundColor: AppColors.warnSoft),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Row(
            children: [
              Expanded(child: Text('Editar ítem', style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                onPressed: _deleting ? null : _delete,
                icon: _deleting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warn))
                    : const Icon(Icons.delete_outline_rounded, color: AppColors.warn, size: 20),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _Field(label: 'Nombre', controller: _nameCtrl),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _Field(label: 'Gramos', controller: _gramsCtrl, numeric: true)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _Field(label: 'Calorías', controller: _kcalCtrl, numeric: true)),
            ],
          ),
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
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar cambios'),
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
