import 'package:flutter/material.dart';
import '../../widgets/nutria_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../home/root_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _step = 0;

  String _goal = 'maintain';
  String _sex = 'm';
  String _activity = 'moderate';
  final _weightCtrl = TextEditingController(text: '75');
  final _heightCtrl = TextEditingController(text: '170');
  final _ageCtrl = TextEditingController(text: '30');
  bool _loading = false;

  static const _goals = [
    (id: 'lose', icon: '📉', label: 'Bajar de peso'),
    (id: 'maintain', icon: '⚖️', label: 'Mantener mi peso'),
    (id: 'gain', icon: '💪', label: 'Ganar masa muscular'),
  ];

  static const _activities = [
    (id: 'sedentary', label: 'Sedentario'),
    (id: 'light', label: 'Actividad leve'),
    (id: 'moderate', label: 'Actividad moderada'),
    (id: 'active', label: 'Activo'),
    (id: 'very_active', label: 'Muy activo'),
  ];

  double get _weight => double.tryParse(_weightCtrl.text) ?? 75;
  int get _height => int.tryParse(_heightCtrl.text) ?? 170;
  int get _age => int.tryParse(_ageCtrl.text) ?? 30;

  int get _previewKcal {
    final bmr = 10 * _weight + 6.25 * _height - 5 * _age + (_sex == 'm' ? 5 : -161);
    const multipliers = {'sedentary': 1.2, 'light': 1.375, 'moderate': 1.55, 'active': 1.725, 'very_active': 1.9};
    final tdee = bmr * (multipliers[_activity] ?? 1.55);
    final target = switch (_goal) {
      'lose' => tdee * 0.8,
      'gain' => tdee * 1.15,
      _ => tdee,
    };
    return target.round();
  }

  void _next() {
    if (_step == 2) {
      _finish();
      return;
    }
    setState(() => _step++);
    _page.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    await NutritionRepository.instance.setGoal(
      goal: _goal,
      weightKg: _weight,
      heightCm: _height,
      age: _age,
      sex: _sex,
      activityLevel: _activity,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(nutriaRoute(const RootShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _step ? AppColors.accent : AppColors.surface2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [_GoalStep(goal: _goal, goals: _goals, onSelect: (g) => setState(() => _goal = g)), _BodyStep(state: this), _ActivityStep(state: this)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _next,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_step == 2 ? 'Empezar' : 'Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.goal, required this.goals, required this.onSelect});
  final String goal;
  final List<({String id, String icon, String label})> goals;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.accentGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            alignment: Alignment.center,
            child: const Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('¿Cuál es tu objetivo?', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text('Vamos a armar tu plan de calorías y macros a medida', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          ...goals.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SelectRow(icon: g.icon, label: g.label, selected: goal == g.id, onTap: () => onSelect(g.id)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyStep extends StatelessWidget {
  const _BodyStep({required this.state});
  final _OnboardingScreenState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Contanos de vos', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text('Con esto calculamos tu gasto calórico real', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: _NumField(label: 'Peso (kg)', controller: state._weightCtrl)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _NumField(label: 'Altura (cm)', controller: state._heightCtrl)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _NumField(label: 'Edad', controller: state._ageCtrl)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setSt) => Row(
                    children: [
                      Expanded(
                        child: _ToggleChip(
                          label: 'Hombre',
                          selected: state._sex == 'm',
                          onTap: () => setSt(() => state._sex = 'm'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ToggleChip(
                          label: 'Mujer',
                          selected: state._sex == 'f',
                          onTap: () => setSt(() => state._sex = 'f'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityStep extends StatefulWidget {
  const _ActivityStep({required this.state});
  final _OnboardingScreenState state;

  @override
  State<_ActivityStep> createState() => _ActivityStepState();
}

class _ActivityStepState extends State<_ActivityStep> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('¿Qué tan activo sos?', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text('Esto ajusta cuántas calorías quemás por día', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          ..._OnboardingScreenState._activities.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SelectRow(
                icon: '',
                label: a.label,
                selected: s._activity == a.id,
                dense: true,
                onTap: () => setState(() => s._activity = a.id),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TU PLAN SUGERIDO', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Text('${s._previewKcal} kcal/día', style: AppTypography.numeric(size: 22)),
                const SizedBox(height: 4),
                Text(
                  'Calculado con tu peso, altura, edad y actividad real',
                  style: const TextStyle(color: AppColors.accent, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
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
              if (icon.isNotEmpty) ...[Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(width: AppSpacing.md)],
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.accent : Colors.transparent,
                  border: Border.all(color: selected ? AppColors.accent : AppColors.border, width: 2),
                ),
                child: selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
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
