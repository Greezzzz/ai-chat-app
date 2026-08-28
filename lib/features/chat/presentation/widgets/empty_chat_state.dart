import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_theme.dart';

/// Empty chat state with suggestion chips (PRD §17).
class EmptyChatState extends StatelessWidget {
  const EmptyChatState({super.key, required this.onSuggestionSelected});

  final ValueChanged<String> onSuggestionSelected;

  static const _suggestions = [
    'Explain quantum computing',
    'Write a product description',
    'Help me debug code',
  ];

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: neo.accent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: neo.border, width: neo.borderWidth),
                boxShadow: neo.shadowSm,
              ),
              child: Icon(Icons.auto_awesome, size: 36, color: neo.ink),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'AI Assistant',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: neo.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'How can I help you today?',
              style: TextStyle(
                fontSize: 15,
                color: neo.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final suggestion in _suggestions) ...[
              _SuggestionChip(
                label: suggestion,
                onTap: () => onSuggestionSelected(suggestion),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;

    return Material(
      color: neo.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        side: BorderSide(color: neo.border, width: neo.borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: neo.ink,
            ),
          ),
        ),
      ),
    );
  }
}
