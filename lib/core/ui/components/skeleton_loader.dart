import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/neo_theme.dart';

/// Neo-brutalism loading skeleton: hard-bordered grey boxes that pulse.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = AppSpacing.md,
    this.radius = AppSpacing.radiusSm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final base = Theme.of(context).brightness == Brightness.dark
            ? neo.surface
            : neo.background;
        final highlight = Color.lerp(
          base,
          neo.surface,
          0.3 + _controller.value * 0.4,
        )!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: highlight,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: neo.border, width: 1),
          ),
        );
      },
    );
  }
}
