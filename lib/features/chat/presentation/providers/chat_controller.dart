import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/create_conversation.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../data/datasources/chat_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import 'chat_usecases.dart';

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
  });

  final List<Conversation> conversations;
  final String? currentConversationId;
  final List<Message> messages;
  final bool isLoadingConversations;
  final bool isLoadingMessages;
  final bool isStreaming;
  final String? errorMessage;

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
    bool clearError = false,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      messages: messages ?? this.messages,
      isLoadingConversations: isLoadingConversations ?? this.isLoadingConversations,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
    this._dataSource,
  ) : super(const ChatState());

  final GetConversations _getConversations;
  final GetMessages _getMessages;
  final CreateConversation _createConversation;
  final SendMessage _sendMessage;
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
      state = state.copyWith(
        messages: messages,
        isLoadingMessages: false,
      );
    } on AppException catch (e) {
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
      );
    } else {
      // Remote: the backend creates the conversation on the first message.
      state = state.copyWith(
        currentConversationId: null,
        messages: const [],
        clearError: true,
      );
    }
    await loadConversations();
  }

  /// Sends a message and streams the assistant response.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final convId = state.currentConversationId;
    final isRemote = !_dataSource.persistsLocally;

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
    state = state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
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
        // brand-new chat completes (the backend created it server-side and
        // the SSE stream doesn't return its id). Existing chats are already
        // in the list — no need to re-fetch.
        if (isRemote && convId == null) {
          await loadConversations();
          final conversations = state.conversations;
          if (conversations.isNotEmpty) {
            // Pick the newest conversation and assign its id to the messages
            // that were just streamed (they were created without an id).
            final created = conversations.first;
            state = state.copyWith(
              currentConversationId: created.id,
              messages: [
                ...state.messages.map(
                  (m) => m.conversationId.isEmpty
                      ? m.copyWith(conversationId: created.id)
                      : m,
                ),
              ],
            );
          }
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

  Future<void> _cancelStream() async {
    _streamThrottle?.cancel();
    _streamThrottle = null;
    await _streamSub?.cancel();
    _streamSub = null;
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
    ref.watch(chatDataSourceProvider),
  );
});
