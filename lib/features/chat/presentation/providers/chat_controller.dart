import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/create_conversation.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/upload_document.dart';
import '../../data/datasources/chat_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import 'chat_usecases.dart';

/// A RAG context document prepared for a brand-new conversation.
///
/// Uploaded to the backend up front; the [documentId] is sent with the first
/// message to bind it to the conversation (per api-spec).
class PendingDocument {
  const PendingDocument({required this.documentId, required this.title});

  final String documentId;
  final String title;
}

/// UI-facing chat state.
class ChatState {
  const ChatState({
    this.conversations = const [],
    this.currentConversationId,
    this.messages = const [],
    this.isLoadingConversations = false,
    this.isLoadingMessages = false,
    this.isStreaming = false,
    this.errorMessage,
    this.pendingDocument,
  });

  final List<Conversation> conversations;
  final String? currentConversationId;
  final List<Message> messages;
  final bool isLoadingConversations;
  final bool isLoadingMessages;
  final bool isStreaming;
  final String? errorMessage;

  /// RAG document uploaded but not yet bound to a conversation (waiting for
  /// the first message). Non-null only in a brand-new, not-yet-started chat.
  final PendingDocument? pendingDocument;

  Conversation? get currentConversation {
    for (final c in conversations) {
      if (c.id == currentConversationId) return c;
    }
    return null;
  }

  ChatState copyWith({
    List<Conversation>? conversations,
    String? currentConversationId,
    List<Message>? messages,
    bool? isLoadingConversations,
    bool? isLoadingMessages,
    bool? isStreaming,
    String? errorMessage,
    PendingDocument? pendingDocument,
    bool clearError = false,
    bool clearPendingDocument = false,
    bool clearCurrentConversation = false,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      currentConversationId: clearCurrentConversation
          ? null
          : (currentConversationId ?? this.currentConversationId),
      messages: messages ?? this.messages,
      isLoadingConversations: isLoadingConversations ?? this.isLoadingConversations,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingDocument: clearPendingDocument
          ? null
          : (pendingDocument ?? this.pendingDocument),
    );
  }
}

/// Manages conversations, message loading and streaming.
class ChatController extends StateNotifier<ChatState> {
  ChatController(
    this._getConversations,
    this._getMessages,
    this._createConversation,
    this._sendMessage,
    this._uploadDocument,
    this._dataSource,
  ) : super(const ChatState());

  final GetConversations _getConversations;
  final GetMessages _getMessages;
  final CreateConversation _createConversation;
  final SendMessage _sendMessage;
  final UploadDocument _uploadDocument;
  final ChatDataSource _dataSource;

  StreamSubscription<String>? _streamSub;
  final StringBuffer _streamBuffer = StringBuffer();
  Timer? _streamThrottle;
  static const _streamThrottleInterval = Duration(milliseconds: 80);

  /// Loads the conversation list into state.
  Future<void> loadConversations() async {
    state = state.copyWith(
      isLoadingConversations: true,
      clearError: true,
    );
    try {
      final conversations = await _getConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoadingConversations: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoadingConversations: false,
        errorMessage: e.message,
      );
    }
  }

  /// Selects a conversation and loads its messages.
  Future<void> selectConversation(String id) async {
    await _cancelStream();
    state = state.copyWith(
      currentConversationId: id,
      isLoadingMessages: true,
      messages: const [],
      clearError: true,
    );
    try {
      final messages = await _getMessages(id);
      // Guard against races: if the user switched away (new chat / another
      // conversation) while messages were loading, don't clobber that state.
      if (state.currentConversationId != id) return;
      state = state.copyWith(
        messages: messages,
        isLoadingMessages: false,
      );
    } on AppException catch (e) {
      if (state.currentConversationId != id) return;
      state = state.copyWith(
        isLoadingMessages: false,
        errorMessage: e.message,
      );
    }
  }

  /// Creates a fresh empty conversation (New Chat).
  Future<void> newConversation() async {
    await _cancelStream();
    if (_dataSource.persistsLocally) {
      final conversation = await _createConversation();
      state = state.copyWith(
        currentConversationId: conversation.id,
        messages: const [],
        clearError: true,
        clearPendingDocument: true,
      );
    } else {
      // Remote: the backend creates the conversation on the first message.
      state = state.copyWith(
        clearCurrentConversation: true,
        messages: const [],
        clearError: true,
        clearPendingDocument: true,
      );
    }
    await loadConversations();
  }

  /// Uploads a RAG context document and keeps it pending until the first
  /// message of the new chat binds it to the conversation.
  Future<bool> addContextDocument({
    required String title,
    required String content,
  }) async {
    try {
      final documentId = await _uploadDocument(
        title: title,
        content: content,
      );
      state = state.copyWith(
        pendingDocument: PendingDocument(
          documentId: documentId,
          title: title,
        ),
        clearError: true,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  /// Discards the pending context document (used when leaving a new chat
  /// without sending the first message).
  void clearPendingDocument() {
    state = state.copyWith(clearPendingDocument: true);
  }

  /// Sends a message and streams the assistant response.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final convId = state.currentConversationId;
    final isRemote = !_dataSource.persistsLocally;
    // A pending document binds to the conversation on the first message.
    final pendingDoc = state.pendingDocument;
    final isFirstMessage = convId == null && pendingDoc != null;

    // Optimistically show the user message.
    final userMessage = Message(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: convId ?? '',
      role: MessageRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    // Placeholder assistant message that will stream.
    final assistantId = 'msg_${DateTime.now().microsecondsSinceEpoch}_ai';
    final assistantMessage = Message(
      id: assistantId,
      conversationId: convId ?? '',
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      status: MessageStatus.streaming,
    );
    _streamBuffer.clear();

    // Drop the last assistant message if it errored (e.g. stream timeout).
    // It was never persisted server-side, so the new attempt replaces it
    // instead of stacking a failed bubble on top of the previous one.
    final messages = state.messages;
    final baseMessages = messages.isNotEmpty &&
            messages.last.status == MessageStatus.error
        ? messages.take(messages.length - 1).toList()
        : messages;

    state = state.copyWith(
      messages: [...baseMessages, userMessage, assistantMessage],
      isStreaming: true,
      clearError: true,
    );

    // If no conversation yet, create it first (mock mode only). In remote
    // mode the backend creates the conversation implicitly on first message.
    String? effectiveConvId = convId;
    if (effectiveConvId == null && !isRemote) {
      final conversation = await _createConversation();
      effectiveConvId = conversation.id;
      state = state.copyWith(currentConversationId: effectiveConvId);
    }

    _streamSub = _sendMessage(
      conversationId: effectiveConvId,
      message: trimmed,
      documentId: pendingDoc?.documentId,
    ).listen(
      (chunk) {
        // Accumulate cheaply; throttle UI rebuilds so long streams don't
        // rebuild the whole list (and re-layout huge text) on every chunk.
        _streamBuffer.write(chunk);
        _streamThrottle ??= Timer(_streamThrottleInterval, () {
          _streamThrottle = null;
          _emitStreamingMessage(assistantMessage);
        });
      },
      onError: (Object error) {
        _streamThrottle?.cancel();
        _streamThrottle = null;
        state = state.copyWith(
          isStreaming: false,
          messages: [
            ...state.messages.take(state.messages.length - 1),
            assistantMessage.copyWith(
              content: _streamBuffer.toString(),
              status: MessageStatus.error,
            ),
          ],
          errorMessage: error is AppException
              ? error.message
              : 'AI response failed.',
        );
      },
      onDone: () async {
        _streamThrottle?.cancel();
        _streamThrottle = null;
        // Mark the assistant message as completed with the full content
        // (the throttle may not have flushed the last chunk yet).
        final messages = state.messages;
        state = state.copyWith(
          isStreaming: false,
          messages: messages.isEmpty
              ? messages
              : [
                  ...messages.take(messages.length - 1),
                  assistantMessage.copyWith(
                    content: _streamBuffer.toString(),
                    status: MessageStatus.completed,
                  ),
                ],
        );

        // Refresh the conversation list ONLY after the first message of a
        // brand-new chat completes (the backend created it server-side).
        // The SSE stream's first event carries the new conversation id, so we
        // bind to that — no guessing which list entry is the new one.
        if (isRemote && convId == null) {
          final createdId = _dataSource.lastConversationId;
          // Ids known before the refresh — used as a fallback to detect the
          // new conversation when the backend didn't report its id.
          final knownIds = state.conversations.map((c) => c.id).toSet();

          if (createdId != null) {
            // Bind directly to the id the backend reported.
            state = state.copyWith(
              currentConversationId: createdId,
              messages: [
                ...state.messages.map(
                  (m) => m.conversationId.isEmpty
                      ? m.copyWith(conversationId: createdId)
                      : m,
                ),
              ],
              clearPendingDocument: isFirstMessage,
            );
          }

          // Refresh the list once so the drawer shows the new conversation
          // (and its title). Happens only after the first message of a new
          // chat, per the flow: send → response → id → list → title.
          await loadConversations();

          // If the backend didn't report an id, detect it by difference from
          // the ids we already knew before the refresh.
          if (createdId == null) {
            final conversations = state.conversations;
            final newOnes =
                conversations.where((c) => !knownIds.contains(c.id)).toList();
            if (newOnes.length == 1) {
              final created = newOnes.first;
              state = state.copyWith(
                currentConversationId: created.id,
                messages: [
                  ...state.messages.map(
                    (m) => m.conversationId.isEmpty
                        ? m.copyWith(conversationId: created.id)
                        : m,
                  ),
                ],
                clearPendingDocument: isFirstMessage,
              );
            } else {
              state = state.copyWith(clearPendingDocument: isFirstMessage);
            }
          }
        } else if (isFirstMessage) {
          // Mock mode: document bound on the first message too.
          state = state.copyWith(clearPendingDocument: true);
        }
      },
    );
  }

  /// Replaces the last (streaming) message with the accumulated content.
  /// Uses an indexed list update instead of re-capturing from state to keep
  /// the steady-state cost at O(1) per rebuild.
  void _emitStreamingMessage(Message assistantMessage) {
    final messages = state.messages;
    if (messages.isEmpty) return;
    final updated = [...messages];
    updated[updated.length - 1] = assistantMessage.copyWith(
      content: _streamBuffer.toString(),
      status: MessageStatus.streaming,
    );
    state = state.copyWith(messages: updated);
  }

  /// Stops an in-flight stream (Stop generation).
  Future<void> stopStreaming() async {
    await _cancelStream();
    state = state.copyWith(isStreaming: false);
    await loadConversations();
  }

  /// Clears all chat state (used on logout so a new login doesn't inherit
  /// the previous session's selected conversation).
  Future<void> reset() async {
    await _cancelStream();
    _streamBuffer.clear();
    state = const ChatState();
  }

  Future<void> _cancelStream() async {
    _streamThrottle?.cancel();
    _streamThrottle = null;
    // Fire-and-forget: cancelling a completed/foreign subscription should
    // never block navigation (some adapters' cancel can hang).
    final sub = _streamSub;
    _streamSub = null;
    unawaited(sub?.cancel());
  }

  @override
  void dispose() {
    _streamThrottle?.cancel();
    _streamSub?.cancel();
    super.dispose();
  }
}

/// Provides the [ChatController], wired to the chat use cases.
final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(
    ref.watch(getConversationsProvider),
    ref.watch(getMessagesProvider),
    ref.watch(createConversationProvider),
    ref.watch(sendMessageProvider),
    ref.watch(uploadDocumentProvider),
    ref.watch(chatDataSourceProvider),
  );
});
