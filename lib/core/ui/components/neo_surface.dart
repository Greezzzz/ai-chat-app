import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/neo_theme.dart';

/// Core neo-brutalism surface: filled box with hard border and offset shadow.
///
/// This is the foundation of every card, input, bubble and button in the app.
/// All surfaces read their tokens from [NeoTheme] so the look stays
/// consistent and theme-aware.
class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.shadow,
    this.borderWidth,
    this.radius = const BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
    this.padding,
    this.onTap,
    this.highlightColor,
  });

  /// Fill color. Defaults to `theme.surface`.
  final Color? color;

  /// The content rendered inside the surface.
  final Widget child;

  /// Border color. Defaults to `theme.border`.
  final Color? borderColor;

  /// Box shadow. Defaults to `theme.shadowMd`.
  final List<BoxShadow>? shadow;

  /// Border thickness. Defaults to `theme.borderWidth`.
  final double? borderWidth;

  final BorderRadius radius;
  final EdgeInsetsGeometry? padding;

  /// When set, the surface behaves as a tappable button (InkWell).
  final VoidCallback? onTap;

  /// Splash color used when [onTap] is set.
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;

    final border = Border.all(
      color: borderColor ?? neo.border,
      width: borderWidth ?? neo.borderWidth,
    );
    final shadowList = shadow ?? neo.shadowMd;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? neo.surface,
        borderRadius: radius,
        border: border,
        boxShadow: shadowList,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: highlightColor ?? neo.accent.withValues(alpha: 0.3),
          highlightColor:
              highlightColor ?? neo.accent.withValues(alpha: 0.15),
          child: content,
        ),
      );
    }

    return content;
  }
}
