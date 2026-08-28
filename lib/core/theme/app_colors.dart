import 'package:flutter/material.dart';

/// Neo-brutalism color palette.
///
/// Light mode: cream background, near-black ink, bold accent colors.
/// Dark mode: deep charcoal background with inverted accents.
class AppColors {
  const AppColors._();

  // ---- Ink / text -------------------------------------------------------
  static const Color ink = Color(0xFF1A1A18); // near-black, warm tint
  static const Color inkMuted = Color(0xFF5C5B57);

  // ---- Light mode -------------------------------------------------------
  static const Color lightBackground = Color(0xFFF5F0E6); // cream paper
  static const Color lightSurface = Color(0xFFFFFFFF); // card / surface
  static const Color lightBorder = Color(0xFF1A1A18); // hard border
  static const Color lightAccent = Color(0xFFFFD84D); // bold yellow
  static const Color lightAccentAlt = Color(0xFF7EE081); // bold green
  static const Color lightError = Color(0xFFFF5A4D); // bold red
  static const Color lightUserBubble = Color(0xFFD9ECFF); // soft blue

  // ---- Dark mode --------------------------------------------------------
  static const Color darkBackground = Color(0xFF171715); // charcoal
  static const Color darkSurface = Color(0xFF232321); // raised surface
  static const Color darkBorder = Color(0xFFEDEAE0); // hard border (light ink)
  static const Color darkAccent = Color(0xFFE9C83F); // muted bold yellow
  static const Color darkAccentAlt = Color(0xFF5FBF62); // muted bold green
  static const Color darkError = Color(0xFFE85246); // muted bold red
  static const Color darkUserBubble = Color(0xFF2E4360); // deep blue

  // ---- Shared -----------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
