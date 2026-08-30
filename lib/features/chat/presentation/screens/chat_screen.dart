import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../core/ui/components/error_state.dart';
import '../../../../core/ui/components/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/conversation.dart';
import '../providers/chat_controller.dart';
import '../widgets/add_context_sheet.dart';
import '../widgets/conversation_drawer.dart';
import '../widgets/empty_chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_composer.dart';

/// Main chat screen: header, message list (auto-scroll + floating button),
/// composer and conversation drawer (PRD §9–§14).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialConversationId});

  final String? initialConversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _drawerKey = GlobalKey<ScaffoldState>();
  bool _userScrolledUp = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(_init);
  }

  Future<void> _init() async {
    await ref.read(chatControllerProvider.notifier).loadConversations();
    final id = widget.initialConversationId ??
        ref.read(chatControllerProvider).currentConversationId;
    if (id != null) {
      await ref.read(chatControllerProvider.notifier).selectConversation(id);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 40;
    if (atBottom != _userScrolledUp) {
      setState(() => _userScrolledUp = !atBottom);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Opens the Add Context sheet, uploads the document and keeps it pending
  /// until the first message binds it to the conversation.
  Future<void> _showAddContext() async {
    final result = await showAddContextSheet(context);
    if (result == null) return; // dismissed
    final ok = await ref.read(chatControllerProvider.notifier).addContextDocument(
          title: result.title,
          content: result.content,
        );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambahkan konteks. Coba lagi.')),
      );
    }
  }

  /// Confirms discarding the pending context when leaving a new chat before
  /// the first message was sent.
  Future<bool> _confirmDiscardPending() async {
    final chat = ref.read(chatControllerProvider);
    if (chat.pendingDocument == null) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konteks belum terpakai'),
        content: const Text(
          'Konteks telah ditambahkan tetapi belum dikirim ke percakapan. '
          'Yakin ingin menghapusnya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (discard == true) {
      ref.read(chatControllerProvider.notifier).clearPendingDocument();
    }
    return discard ?? false;
  }

  /// Leaves the current new chat (back / new chat). Confirms first when a
  /// pending context would be lost.
  Future<void> _leaveChat() async {
    if (!await _confirmDiscardPending()) return;
    if (mounted) {
      ref.read(chatControllerProvider.notifier).newConversation();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;
    final chat = ref.watch(chatControllerProvider);
    final notifier = ref.read(chatControllerProvider.notifier);

    final groups = _groupConversations(chat.conversations);

    return PopScope(
      canPop: chat.pendingDocument == null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmDiscardPending();
      },
      child: Scaffold(
        key: _drawerKey,
        drawer: ConversationDrawer(
          groups: groups,
          activeId: chat.currentConversationId,
          onSelect: (id) {
            _drawerKey.currentState?.closeDrawer();
            notifier.selectConversation(id);
          },
          onNewChat: () {
            _drawerKey.currentState?.closeDrawer();
            _leaveChat();
          },
          onLogout: () {
            _drawerKey.currentState?.closeDrawer();
            // Clear chat state (selected conversation, messages) so the next
            // login starts fresh, then log out (router redirects to /login).
            notifier.reset();
            ref.read(authControllerProvider.notifier).logout();
          },
        ),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Open history',
            onPressed: () => _drawerKey.currentState?.openDrawer(),
          ),
          title: Text(chat.currentConversation?.title ?? 'AI Assistant'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'New chat',
              onPressed: _leaveChat,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildBody(chat, notifier)),
            if (chat.pendingDocument != null)
              _ContextChip(title: chat.pendingDocument!.title),
            MessageComposer(
              isStreaming: chat.isStreaming,
              isUploadingContext: chat.isUploadingContext,
              onSend: notifier.sendMessage,
              onStop: notifier.stopStreaming,
            ),
          ],
        ),
        floatingActionButton: _userScrolledUp && chat.messages.isNotEmpty
            ? FloatingActionButton.small(
                onPressed: _scrollToBottom,
                tooltip: 'Scroll to latest',
                backgroundColor: neo.accent,
                foregroundColor: neo.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(color: neo.border, width: neo.borderWidth),
                ),
                child: const Icon(Icons.arrow_downward_rounded),
              )
            : null,
      ),
    );
  }

  Widget _buildBody(ChatState chat, ChatController notifier) {
    if (chat.errorMessage != null && chat.messages.isEmpty) {
      return ErrorState(
        message: chat.errorMessage!,
        onRetry: () {
          final id = chat.currentConversationId;
          if (id != null) {
            notifier.selectConversation(id);
          } else {
            notifier.loadConversations();
          }
        },
      );
    }

    if (chat.isLoadingMessages) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          SkeletonLoader(height: 48),
          SizedBox(height: AppSpacing.sm),
          SkeletonLoader(height: 48),
          SizedBox(height: AppSpacing.sm),
          SkeletonLoader(height: 48),
        ],
      );
    }

    if (chat.messages.isEmpty) {
      return EmptyChatState(
        // Only allow attaching a context to a brand-new, not-yet-started chat.
        onAddContext: chat.currentConversationId == null
            ? _showAddContext
            : null,
        pendingDocumentTitle: chat.pendingDocument?.title,
        isUploadingContext: chat.isUploadingContext,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: chat.messages[index]);
      },
    );
  }

  List<ConversationGroup> _groupConversations(List<Conversation> conversations) {
    if (conversations.isEmpty) return const [];
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

    final today = <Conversation>[];
    final yesterday = <Conversation>[];
    final older = <Conversation>[];

    for (final c in conversations) {
      if (c.updatedAt.isAfter(startOfToday)) {
        today.add(c);
      } else if (c.updatedAt.isAfter(startOfYesterday)) {
        yesterday.add(c);
      } else {
        older.add(c);
      }
    }

    return [
      if (today.isNotEmpty) ConversationGroup('Today', today),
      if (yesterday.isNotEmpty) ConversationGroup('Yesterday', yesterday),
      if (older.isNotEmpty) ConversationGroup('Older', older),
    ];
  }
}

/// Small indicator above the composer showing the pending context document
/// that will be bound to the conversation on the first message.
class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: neo.accent.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: neo.border, width: neo.borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file_rounded, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
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
