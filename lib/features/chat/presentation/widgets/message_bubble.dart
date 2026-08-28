import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/message.dart';

/// A single chat message bubble.
///
/// User messages align right (accent-tinted), assistant messages align left
/// (surface). Streaming messages show a trailing cursor; errored messages
/// show a warning icon.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;
    final isUser = message.role == MessageRole.user;
    final isStreaming = message.status == MessageStatus.streaming;
    final isError = message.status == MessageStatus.error;

    final background = isUser ? neo.userBubble : neo.surface;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppSpacing.radiusMd),
      topRight: const Radius.circular(AppSpacing.radiusMd),
      bottomLeft: Radius.circular(isUser ? AppSpacing.radiusMd : 2),
      bottomRight: Radius.circular(isUser ? 2 : AppSpacing.radiusMd),
    );

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(color: neo.border, width: neo.borderWidth),
        boxShadow: isUser ? neo.shadowSm : neo.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content.isEmpty && isStreaming ? ' ' : message.content,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: isUser ? neo.ink : neo.ink,
            ),
          ),
          if (isStreaming)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '▌',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: neo.ink,
                ),
              ),
            ),
          if (isError && message.content.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 16, color: neo.error),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Failed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: neo.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: neo.accent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: neo.border, width: 1.5),
              ),
              child: const Icon(Icons.auto_awesome, size: 16),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
