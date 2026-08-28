import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shadows.dart';

/// Theme extension that exposes neo-brutalism design tokens to widgets.
///
/// Access via:
/// ```dart
/// final neo = Theme.of(context).extension<NeoTheme>()!;
/// ```
class NeoTheme extends ThemeExtension<NeoTheme> {
  const NeoTheme({
    required this.background,
    required this.surface,
    required this.border,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.accentAlt,
    required this.error,
    required this.userBubble,
    required this.borderWidth,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
  });

  // ---- Colors -----------------------------------------------------------
  final Color background;
  final Color surface;
  final Color border;
  final Color ink;
  final Color inkMuted;
  final Color accent;
  final Color accentAlt;
  final Color error;
  final Color userBubble;

  // ---- Effects ----------------------------------------------------------
  final double borderWidth;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;

  static const light = NeoTheme(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    border: AppColors.lightBorder,
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    accent: AppColors.lightAccent,
    accentAlt: AppColors.lightAccentAlt,
    error: AppColors.lightError,
    userBubble: AppColors.lightUserBubble,
    borderWidth: 2,
    shadowSm: AppShadows.sm,
    shadowMd: AppShadows.md,
    shadowLg: AppShadows.lg,
  );

  static const dark = NeoTheme(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    border: AppColors.darkBorder,
    ink: AppColors.darkBorder,
    inkMuted: Color(0xFF9E9B90),
    accent: AppColors.darkAccent,
    accentAlt: AppColors.darkAccentAlt,
    error: AppColors.darkError,
    userBubble: AppColors.darkUserBubble,
    borderWidth: 2,
    shadowSm: AppShadows.sm,
    shadowMd: AppShadows.md,
    shadowLg: AppShadows.lg,
  );

  @override
  NeoTheme copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? ink,
    Color? inkMuted,
    Color? accent,
    Color? accentAlt,
    Color? error,
    Color? userBubble,
    double? borderWidth,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
  }) {
    return NeoTheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      accent: accent ?? this.accent,
      accentAlt: accentAlt ?? this.accentAlt,
      error: error ?? this.error,
      userBubble: userBubble ?? this.userBubble,
      borderWidth: borderWidth ?? this.borderWidth,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
    );
  }

  @override
  NeoTheme lerp(NeoTheme? other, double t) {
    if (other is! NeoTheme) return this;
    return NeoTheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentAlt: Color.lerp(accentAlt, other.accentAlt, t)!,
      error: Color.lerp(error, other.error, t)!,
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      shadowSm: t < 0.5 ? shadowSm : other.shadowSm,
      shadowMd: t < 0.5 ? shadowMd : other.shadowMd,
      shadowLg: t < 0.5 ? shadowLg : other.shadowLg,
    );
  }
}
