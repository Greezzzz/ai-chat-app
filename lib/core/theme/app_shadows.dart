import 'package:flutter/material.dart';

/// Neo-brutalism shadow: hard offset, no blur.
///
/// Shadows use a solid black offset (3/5/7 px) with zero blur to create the
/// signature "sticker" depth of the style.
abstract final class AppShadows {
  /// Small shadow — buttons, chips, small surfaces.
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0xFF000000),
      offset: Offset(3, 3),
      blurRadius: 0,
    ),
  ];

  /// Medium shadow — cards, inputs, message bubbles.
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0xFF000000),
      offset: Offset(5, 5),
      blurRadius: 0,
    ),
  ];

  /// Large shadow — drawers, modals, prominent surfaces.
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0xFF000000),
      offset: Offset(7, 7),
      blurRadius: 0,
    ),
  ];

  static const List<BoxShadow> none = [];
}
