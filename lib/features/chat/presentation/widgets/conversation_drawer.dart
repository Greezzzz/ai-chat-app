import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/conversation.dart';
import 'conversation_tile.dart';

/// Groups conversations by relative day (Today / Yesterday / Older).
class ConversationGroup {
  const ConversationGroup(this.label, this.conversations);

  final String label;
  final List<Conversation> conversations;
}

/// Drawer with conversation history grouped by day (PRD §14).
class ConversationDrawer extends StatelessWidget {
  const ConversationDrawer({
    super.key,
    required this.groups,
    required this.activeId,
    required this.onSelect,
    required this.onNewChat,
    this.onLogout,
  });

  final List<ConversationGroup> groups;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final VoidCallback onNewChat;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chatly',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: neo.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Material(
                color: neo.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(color: neo.border, width: neo.borderWidth),
                ),
                child: InkWell(
                  onTap: onNewChat,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'New Chat',
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
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Text(
                        'No conversations yet',
                        style: TextStyle(color: neo.inkMuted),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      children: [
                        for (final group in groups) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.sm,
                              AppSpacing.sm,
                              AppSpacing.sm,
                              AppSpacing.xs,
                            ),
                            child: Text(
                              group.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: neo.inkMuted,
                              ),
                            ),
                          ),
                          for (final c in group.conversations)
                            ConversationTile(
                              conversation: c,
                              isActive: c.id == activeId,
                              onTap: () => onSelect(c.id),
                            ),
                        ],
                      ],
                    ),
            ),
            if (onLogout != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Material(
                  color: neo.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: BorderSide(
                      color: neo.border,
                      width: neo.borderWidth,
                    ),
                  ),
                  child: InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: neo.error),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: neo.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
