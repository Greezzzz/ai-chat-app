import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/neo_theme.dart';

/// Inline error banner for form-level failures (e.g. "Email already
/// registered"). Hidden when [message] is null.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    final neo = Theme.of(context).extension<NeoTheme>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: neo.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: neo.error, width: neo.borderWidth),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: neo.error),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: neo.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
