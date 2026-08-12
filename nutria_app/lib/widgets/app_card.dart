import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card base sólida (no-glass) para listas e ítems de contenido.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}
