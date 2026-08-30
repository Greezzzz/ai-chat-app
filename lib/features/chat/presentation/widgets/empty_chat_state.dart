import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_theme.dart';

/// Empty chat state for a brand-new chat (PRD §17).
///
/// Shows a single action: attach a RAG context document. No suggestion
/// chips — they looked like prompts and clashed with the context action.
class EmptyChatState extends StatelessWidget {
  const EmptyChatState({
    super.key,
    this.onAddContext,
    this.pendingDocumentTitle,
    this.isUploadingContext = false,
  });

  /// Shown when the user can attach a RAG context to a brand-new chat.
  final VoidCallback? onAddContext;

  /// Title of a pending context document (shown as a chip when set).
  final String? pendingDocumentTitle;

  /// True while a context document is uploading; the button is disabled.
  final bool isUploadingContext;

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
            if (onAddContext != null) ...[
              const SizedBox(height: AppSpacing.xl),
              if (isUploadingContext) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Menyiapkan konteks...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: neo.inkMuted,
                  ),
                ),
              ] else if (pendingDocumentTitle != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: neo.accent.withValues(alpha: 0.25),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: neo.border,
                      width: neo.borderWidth,
                    ),
                  ),
                  child: Text(
                    '📎 $pendingDocumentTitle',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: neo.ink,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (!isUploadingContext)
                _ActionButton(
                  label: pendingDocumentTitle != null
                      ? 'Ganti konteks'
                      : 'Add context',
                  onTap: onAddContext!,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;

    return Material(
      color: neo.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: neo.border, width: neo.borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_file_rounded, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: neo.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
