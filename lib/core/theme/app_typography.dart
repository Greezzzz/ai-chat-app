import 'package:flutter/material.dart';

/// Typography ramp shared by light and dark themes.
///
/// Uses the default platform font (per PRD §32) with a deliberate weight
/// scale for hierarchy. Sizes follow a consistent progression.
abstract final class AppTypography {
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Map the ramp into a [TextTheme] so Material widgets inherit it.
  static TextTheme textTheme(Color ink) => TextTheme(
        displayLarge: display.copyWith(color: ink),
        headlineLarge: headline.copyWith(color: ink),
        titleLarge: title.copyWith(color: ink),
        bodyLarge: body.copyWith(color: ink),
        bodyMedium: body.copyWith(fontSize: 14, color: ink),
        labelLarge: label.copyWith(color: ink),
        labelMedium: caption.copyWith(color: ink),
      );
}
