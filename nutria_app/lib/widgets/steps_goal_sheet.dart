import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _presets = [4000, 6000, 8000, 10000, 12000, 15000];

/// Selector de objetivo diario de pasos — presets rápidos + opción de
/// escribir un número propio, mismo patrón que usa Samsung Health.
/// Devuelve el objetivo elegido, o null si se cerró sin cambiar nada.
Future<int?> showStepsGoalSheet(BuildContext context, {required int current}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (context) => _StepsGoalSheet(current: current),
  );
}

class _StepsGoalSheet extends StatefulWidget {
  const _StepsGoalSheet({required this.current});
  final int current;

  @override
  State<_StepsGoalSheet> createState() => _StepsGoalSheetState();
}

class _StepsGoalSheetState extends State<_StepsGoalSheet> {
  late final _customCtrl = TextEditingController(text: _presets.contains(widget.current) ? '' : widget.current.toString());

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
          Text('Objetivo diario de pasos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Elegí una meta o escribí la tuya', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets
                .map(
                  (p) => GestureDetector(
                    onTap: () => Navigator.of(context).pop(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: p == widget.current ? AppColors.accentSoft : AppColors.surface2,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: p == widget.current ? AppColors.accent : AppColors.border),
                      ),
                      child: Text(
                        '$p',
                        style: TextStyle(
                          color: p == widget.current ? AppColors.accent : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _customCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Otro número',
              labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              suffixText: 'pasos',
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.accent)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final value = int.tryParse(_customCtrl.text);
                if (value != null && value >= 1000) Navigator.of(context).pop(value);
              },
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
