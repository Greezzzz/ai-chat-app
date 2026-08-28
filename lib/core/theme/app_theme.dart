import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'app_typography.dart';
import 'neo_theme.dart';

/// Builds the [ThemeData] used across the app.
///
/// All colors, effects and typography are driven by [NeoTheme] so screens
/// only ever read tokens from `Theme.of(context)` — never raw constants.
abstract final class AppTheme {
  static ThemeData get light => _build(NeoTheme.light, Brightness.light);

  static ThemeData get dark => _build(NeoTheme.dark, Brightness.dark);

  static ThemeData _build(NeoTheme neo, Brightness brightness) {
    final textTheme = AppTypography.textTheme(neo.ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: neo.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: neo.accent,
        brightness: brightness,
        primary: neo.accent,
        surface: neo.surface,
        error: neo.error,
      ),
      extensions: [neo],
      textTheme: textTheme,
      fontFamily: null,

      // ---- AppBar ------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: neo.background,
        foregroundColor: neo.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title.copyWith(color: neo.ink),
        iconTheme: IconThemeData(color: neo.ink, size: 24),
      ),

      // ---- Drawer ------------------------------------------------------
      drawerTheme: DrawerThemeData(
        backgroundColor: neo.background,
        scrimColor: Colors.black.withValues(alpha: 0.4),
      ),

      // ---- Input -------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neo.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: neo.inkMuted,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: textTheme.bodyMedium?.copyWith(
          color: neo.error,
          fontWeight: FontWeight.w700,
        ),
        border: _neoBorder(neo, focused: false),
        enabledBorder: _neoBorder(neo, focused: false),
        focusedBorder: _neoBorder(neo, focused: true),
        errorBorder: _neoBorder(neo, focused: false, isError: true),
        focusedErrorBorder: _neoBorder(neo, focused: true, isError: true),
      ),

      // ---- Buttons -----------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: neo.ink,
          foregroundColor: neo.background,
          disabledBackgroundColor: neo.inkMuted,
          textStyle: AppTypography.label,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(color: neo.border, width: neo.borderWidth),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neo.accent,
          foregroundColor: neo.ink,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: AppTypography.label,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(color: neo.border, width: neo.borderWidth),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neo.ink,
          textStyle: AppTypography.label,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
      ),

      // ---- Chip --------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: neo.surface,
        selectedColor: neo.accent,
        side: BorderSide(color: neo.border, width: neo.borderWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        labelStyle: AppTypography.label.copyWith(color: neo.ink),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // ---- Dialogs / snackbars ----------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: neo.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: neo.border, width: neo.borderWidth),
        ),
        titleTextStyle: AppTypography.title.copyWith(color: neo.ink),
        contentTextStyle: textTheme.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: neo.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: neo.background,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: neo.border, width: 1),
        ),
      ),

      // ---- List tiles --------------------------------------------------
      listTileTheme: ListTileThemeData(
        iconColor: neo.ink,
        textColor: neo.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  static OutlineInputBorder _neoBorder(
    NeoTheme neo, {
    required bool focused,
    bool isError = false,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(
        color: isError
            ? neo.error
            : focused
                ? neo.ink
                : neo.border,
        width: neo.borderWidth + (focused ? 1 : 0),
      ),
    );
  }
}
