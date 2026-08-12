import 'package:flutter/material.dart';
import '../../widgets/nutria_route.dart';

import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_screen.dart';
import '../coach/coach_screen.dart';
import '../diary/diary_screen.dart';
import '../fasting/fasting_screen.dart';
import '../micronutrients/micronutrients_screen.dart';
import '../premium/premium_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../recipes/recipes_screen.dart';
import '../weight/weight_screen.dart';
import 'today_screen.dart';

/// Shell principal con bottom nav custom (no el de Material por defecto):
/// indicador con pill de fondo animada, ícono relleno solo en el tab activo.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.donut_large_outlined, iconOn: Icons.donut_large, label: 'Hoy'),
    (icon: Icons.menu_book_outlined, iconOn: Icons.menu_book, label: 'Diario'),
    (icon: Icons.auto_awesome_outlined, iconOn: Icons.auto_awesome, label: 'Coach'),
    (icon: Icons.show_chart_outlined, iconOn: Icons.show_chart_rounded, label: 'Progreso'),
    (icon: Icons.person_outline, iconOn: Icons.person, label: 'Más'),
  ];

  final _screens = const [
    TodayScreen(),
    DiaryScreen(),
    CoachScreen(),
    ProgressScreen(),
    _MoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final t = _tabs[i];
              final active = i == _index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accentSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(active ? t.iconOn : t.icon, size: 20, color: active ? AppColors.accent : AppColors.textMuted),
                        const SizedBox(height: 3),
                        Text(t.label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: active ? AppColors.accent : AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Más', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.lg),
          _MoreRow(
            icon: Icons.timer_outlined,
            label: 'Ayuno intermitente',
            onTap: () => Navigator.of(context).push(nutriaRoute(const FastingScreen())),
          ),
          _MoreRow(
            icon: Icons.person_outline,
            label: 'Tu perfil',
            onTap: () => Navigator.of(context).push(nutriaRoute(const ProfileScreen())),
          ),
          _MoreRow(
            icon: Icons.menu_book_outlined,
            label: 'Recetas',
            onTap: () => Navigator.of(context).push(nutriaRoute(const RecipesScreen())),
          ),
          _MoreRow(
            icon: Icons.monitor_weight_outlined,
            label: 'Tu peso',
            onTap: () => Navigator.of(context).push(nutriaRoute(const WeightScreen())),
          ),
          _MoreRow(
            icon: Icons.science_outlined,
            label: 'Micronutrientes',
            onTap: () => Navigator.of(context).push(nutriaRoute(const MicronutrientsScreen())),
          ),
          _MoreRow(
            icon: Icons.workspace_premium_outlined,
            label: 'Nutria Pro',
            onTap: () => Navigator.of(context).push(nutriaRoute(const PremiumScreen())),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MoreRow(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesión',
            danger: true,
            onTap: () async {
              await ApiClient.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(nutriaRoute(const AuthScreen()), (route) => false);
            },
          ),
        ],
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.icon, required this.label, required this.onTap, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Icon(icon, size: 18, color: danger ? AppColors.warn : AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: danger ? AppColors.warn : AppColors.textPrimary)),
              ),
              if (!danger) const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
