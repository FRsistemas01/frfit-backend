import 'package:flutter/material.dart';

import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

const _features = [
  ('Chat ilimitado con el coach IA', 'Gratis: unos pocos mensajes por día'),
  ('Foto con IA sin límite', 'Gratis: unas pocas fotos por día'),
  ('Plan de comidas armado por un profesional', 'Exclusivo Premium'),
  ('Recetas guardadas sin límite', 'Gratis: hasta un puñado'),
  ('Historial y gráficos completos', 'Gratis: solo lo reciente'),
];

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _annual = true;
  bool _loading = true;
  bool _isPremium = false;
  Map<String, dynamic>? _usage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await NutritionRepository.instance.premiumStatus();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _isPremium = status?['is_premium'] == true;
      _usage = status?['usage'] as Map<String, dynamic>?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.xl),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Column(
                children: [
                  Text(
                    _isPremium ? 'YA SOS PREMIUM' : 'FRFIT PREMIUM',
                    style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(_isPremium ? 'Tenés todo desbloqueado' : 'La versión completa', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
            else
              Column(
                children: _features
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _FeatureRow(title: f.$1, subtitle: f.$2, unlocked: _isPremium),
                        ))
                    .toList(),
              ),
            if (!_isPremium && _usage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _UsageCard(usage: _usage!),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (!_isPremium) ...[
              Row(
                children: [
                  Expanded(child: _PlanCard(label: 'Mensual', price: '\$4.900', selected: !_annual, onTap: () => setState(() => _annual = false))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _PlanCard(label: 'Anual', price: '\$2.900', save: 'Ahorrás 40%', selected: _annual, onTap: () => setState(() => _annual = true))),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El cobro con Mercado Pago todavía no está conectado — ya viene.')),
                  ),
                  child: const Text('Quiero ser Premium'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.title, required this.subtitle, required this.unlocked});
  final String title;
  final String subtitle;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Icon(unlocked ? Icons.check_circle : Icons.lock_outline, size: 18, color: unlocked ? AppColors.accent : AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage});
  final Map<String, dynamic> usage;

  static const _labels = {
    'coach_chat': 'Mensajes al coach hoy',
    'scan_photo': 'Fotos con IA hoy',
    'recipes_saved': 'Recetas guardadas',
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tu uso del plan free', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in _labels.entries)
            if (usage[entry.key] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                    Text(
                      '${usage[entry.key]['used']}/${usage[entry.key]['limit']}',
                      style: AppTypography.numeric(size: 12),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.label, required this.price, this.save, required this.selected, required this.onTap});
  final String label;
  final String price;
  final String? save;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(price, style: AppTypography.numeric(size: 15)),
            if (save != null) Text(save!, style: const TextStyle(color: AppColors.good, fontSize: 9.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
