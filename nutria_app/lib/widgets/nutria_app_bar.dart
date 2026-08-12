import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Header custom (no el AppBar plano de Material): título grande estilo
/// headline, botón de volver circular con blur — coherente con el resto
/// del sistema visual en vez de una barra genérica.
class NutriaHeader extends StatelessWidget implements PreferredSizeWidget {
  const NutriaHeader({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
        child: Row(
          children: [
            _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop()),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
            ...?actions,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 15, color: AppColors.textPrimary)),
      ),
    );
  }
}
