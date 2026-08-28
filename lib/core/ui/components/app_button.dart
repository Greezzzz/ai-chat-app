import 'package:flutter/material.dart';

import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/neo_theme.dart';
import 'neo_surface.dart';

/// Button variants.
enum AppButtonVariant { primary, secondary, destructive, ghost }

/// Reusable neo-brutalism button with consistent border, hard shadow and
/// loading state. Used everywhere a tap action is needed.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// Shows a spinner and disables the button.
  final bool loading;

  /// When true the button fills the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;
    final isEnabled = onPressed != null && !loading;

    final (background, foreground) = switch (variant) {
      AppButtonVariant.primary => (neo.accent, neo.ink),
      AppButtonVariant.secondary => (neo.surface, neo.ink),
      AppButtonVariant.destructive => (neo.error, neo.ink),
      AppButtonVariant.ghost => (neo.background, neo.ink),
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: AppSpacing.xs),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isEnabled
                  ? foreground
                  : foreground.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );

    final surface = NeoSurface(
      onTap: isEnabled ? onPressed : null,
      color: background,
      borderColor: neo.border,
      borderWidth: neo.borderWidth,
      radius: BorderRadius.circular(AppSpacing.radiusMd),
      shadow: isEnabled ? neo.shadowSm : AppShadows.none,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 4,
      ),
      highlightColor: neo.accentAlt,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: content,
      ),
    );

    return surface;
  }
}
