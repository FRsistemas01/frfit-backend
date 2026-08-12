import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutria_app_bar.dart';

const _goals = [
  (id: 'lose', icon: '📉', label: 'Bajar de peso'),
  (id: 'maintain', icon: '⚖️', label: 'Mantener mi peso'),
  (id: 'gain', icon: '💪', label: 'Ganar masa muscular'),
];

const _activities = [
  (id: 'sedentary', label: 'Sedentario'),
  (id: 'light', label: 'Actividad leve'),
  (id: 'moderate', label: 'Actividad moderada'),
  (id: 'active', label: 'Activo'),
  (id: 'very_active', label: 'Muy activo'),
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  String _goal = 'maintain';
  String _sex = 'm';
  String _activity = 'moderate';
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await NutritionRepository.instance.getProfile();
    if (!mounted || p == null) return;
    setState(() {
      _profile = p;
      _goal = p.goal;
      _sex = p.sex;
      _activity = p.activityLevel;
      _weightCtrl.text = (p.currentWeightKg ?? 75).toStringAsFixed(1);
      _targetWeightCtrl.text = p.targetWeightKg?.toStringAsFixed(1) ?? '';
      _heightCtrl.text = p.heightCm.toString();
      _ageCtrl.text = p.age.toString();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await NutritionRepository.instance.setGoal(
      goal: _goal,
      weightKg: double.tryParse(_weightCtrl.text) ?? 75,
      heightCm: int.tryParse(_heightCtrl.text) ?? 170,
      age: int.tryParse(_ageCtrl.text) ?? 30,
      sex: _sex,
      activityLevel: _activity,
      targetWeightKg: double.tryParse(_targetWeightCtrl.text),
    );
    DiaryBus.instance.refresh();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado — tu plan se recalculó 🎉'), backgroundColor: AppColors.goodSoft),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;

    return Scaffold(
      appBar: const NutriaHeader(title: 'Tu perfil'),
      body: p == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.accentGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.username.isNotEmpty ? p.username[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.username, style: Theme.of(context).textTheme.titleLarge),
                          Text('${p.dailyKcalTarget} kcal/día actuales', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('OBJETIVO', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                ..._goals.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SelectRow(icon: g.icon, label: g.label, selected: _goal == g.id, onTap: () => setState(() => _goal = g.id)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('DATOS', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _NumField(label: 'Peso (kg)', controller: _weightCtrl)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _NumField(label: 'Peso objetivo (kg)', controller: _targetWeightCtrl)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _NumField(label: 'Altura (cm)', controller: _heightCtrl),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _NumField(label: 'Edad', controller: _ageCtrl)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _ToggleChip(label: 'Hombre', selected: _sex == 'm', onTap: () => setState(() => _sex = 'm'))),
                          const SizedBox(width: 6),
                          Expanded(child: _ToggleChip(label: 'Mujer', selected: _sex == 'f', onTap: () => setState(() => _sex = 'f'))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('ACTIVIDAD', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                ..._activities.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SelectRow(icon: '', label: a.label, dense: true, selected: _activity == a.id, onTap: () => setState(() => _activity = a.id)),
                  ),
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
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({required this.icon, required this.label, required this.selected, required this.onTap, this.dense = false});
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(dense ? AppSpacing.sm + 2 : AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
          ),
          child: Row(
            children: [
              if (icon.isNotEmpty) ...[Text(icon, style: const TextStyle(fontSize: 18)), const SizedBox(width: AppSpacing.sm)],
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.accent : Colors.transparent,
                  border: Border.all(color: selected ? AppColors.accent : AppColors.border, width: 2),
                ),
                child: selected ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? AppColors.accent : AppColors.textPrimary)),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
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
