// Widget tests for the authentication flow.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat_app/core/storage/app_database.dart';
import 'package:chat_app/core/storage/seed_data.dart';
import 'package:chat_app/core/storage/session_store.dart';
import 'package:chat_app/core/storage/storage_providers.dart';
import 'package:chat_app/core/utils/hash_util.dart';
import 'package:chat_app/features/chat/data/datasources/chat_data_source.dart';
import 'package:chat_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chat_app/features/chat/domain/entities/conversation.dart';
import 'package:chat_app/features/chat/domain/entities/message.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:chat_app/main.dart';

/// Hive is initialized once in `setUpAll` (real async zone, outside the
/// widget-test FakeAsync zone where file I/O cannot run).
late final AppDatabase db;

Future<void> initTestStorageOnce() async {
  final tempDir = await Directory.systemTemp.createTemp('chat_app_test_');
  db = await AppDatabase.init(path: tempDir.path);
  await SeedData(db, const HashUtil()).seedIfNeeded();
}

/// Fake chat repository — pure in-memory, never touches Hive.
class _FakeChatRepository implements ChatRepository {
  final _conversations = <Conversation>[];
  final _messages = <String, List<Message>>{};

  @override
  Future<List<Conversation>> getConversations() async =>
      List.of(_conversations);

  @override
  Future<Conversation?> getConversation(String id) async {
    for (final c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async =>
      List.of(_messages[conversationId] ?? const []);

  @override
  Future<Conversation> createConversation() async {
    final now = DateTime.now();
    final c = Conversation(
      id: 'conv_test_${_conversations.length + 1}',
      userId: 'user_001',
      title: 'New Chat',
      createdAt: now,
      updatedAt: now,
    );
    _conversations.insert(0, c);
    _messages[c.id] = [];
    return c;
  }

  @override
  Future<void> updateConversation(Conversation conversation) async {
    final i = _conversations.indexWhere((c) => c.id == conversation.id);
    if (i != -1) _conversations[i] = conversation;
  }

  @override
  Future<String> uploadDocument({
    required String title,
    required String content,
  }) async =>
      'doc_${_conversations.length + 1}';

  @override
  Stream<String> sendMessage({
    required String? conversationId,
    required String message,
    String? documentId,
  }) async* {
    final convId =
        conversationId ?? (await createConversation()).id;

    final now = DateTime.now();
    _messages.putIfAbsent(convId, () => []).add(Message(
          id: 'msg_user_$now',
          conversationId: convId,
          role: MessageRole.user,
          content: message,
          createdAt: now,
        ));

    // Yield word chunks with a tiny delay so the UI can observe streaming.
    const response = 'Pertanyaan yang bagus! Ini adalah jawaban demo untuk '
        'menguji streaming.';
    for (final word in response.split(' ')) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      yield '$word ';
    }
  }
}

/// Creates a fresh provider container per test with the shared Hive db and a
/// mocked SharedPreferences session.
Future<ProviderContainer> makeContainer({List<Override> extraOverrides = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    ...extraOverrides,
  ]);
  final sessionStore = SessionStore(await SharedPreferences.getInstance());
  container.read(sessionStoreProvider.notifier).attach(sessionStore);
  return container;
}

/// Remote-like data source: reports no local persistence so the controller
/// treats it as the production API (no Hive, no pre-created conversations).
class _RemoteFakeDataSource implements ChatDataSource {
  @override
  bool get persistsLocally => false;

  @override
  Future<List<Conversation>> getConversations() async => const [];

  @override
  Future<Conversation?> getConversation(String id) async => null;

  @override
  Future<List<Message>> getMessages(String conversationId) async => const [];

  @override
  Future<Conversation> createConversation() async =>
      throw UnimplementedError();

  @override
  Future<void> updateConversation(Conversation conversation) async {}

  @override
  Future<String> uploadDocument({
    required String title,
    required String content,
  }) async =>
      'doc_1';

  @override
  Stream<String> streamChat({
    required String conversationId,
    required String message,
    String? documentId,
  }) async* {
    yield 'placeholder';
  }
}

/// Remote-like fake: the backend owns conversations, so `createConversation`
/// is NOT used for new chats — the conversation appears only after the first
/// message streams (mimics POST /api/chat/stream + re-list).
class _RemoteFakeChatRepository implements ChatRepository {
  final _conversations = <Conversation>[];
  int _nextId = 1;

  @override
  Future<List<Conversation>> getConversations() async =>
      List.of(_conversations);

  @override
  Future<Conversation?> getConversation(String id) async {
    for (final c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async => const [];

  @override
  Future<Conversation> createConversation() async =>
      throw UnimplementedError('Remote creates conversations on first message');

  @override
  Future<void> updateConversation(Conversation conversation) async {}

  @override
  Future<String> uploadDocument({
    required String title,
    required String content,
  }) async =>
      'doc_$_nextId';

  @override
  Stream<String> sendMessage({
    required String? conversationId,
    required String message,
    String? documentId,
  }) async* {
    // Backend creates the conversation server-side on first message.
    final convId = conversationId ?? 'conv_${_nextId++}';
    if (conversationId == null) {
      _conversations.insert(
        0,
        Conversation(
          id: convId,
          userId: 'user_001',
          title: message,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          documentId: documentId,
        ),
      );
    }

    // Short response: completes quickly (tests the short-chat path).
    const response = 'Jawaban singkat.';
    final words = response.split(' ');
    for (var i = 0; i < words.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      yield words[i] + (i == words.length - 1 ? '' : ' ');
    }
  }
}

void main() {
  setUpAll(initTestStorageOnce);

  testWidgets('Boots and redirects to login when not authenticated',
      (tester) async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ChatApp()),
    );

    // Let the splash restore the session and redirect.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Welcome back! Sign in to continue.'), findsOneWidget);
  });

  testWidgets('Logs in with the seed account and reaches chat',
      (tester) async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ChatApp()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Fill the login form.
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'john_doe',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Chat screen should show the empty state.
    expect(find.text('How can I help you today?'), findsOneWidget);
  });

  testWidgets('Shows validation errors for invalid credentials',
      (tester) async {
    final container = await makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ChatApp()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextFormField).at(0), 'ab');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text('Login'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Username must be at least 3 characters'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('Full chat flow: login, new chat, send, streaming response',
      (tester) async {
    final fakeRepo = _FakeChatRepository();
    final container = await makeContainer(extraOverrides: [
      chatRepositoryProvider.overrideWithValue(fakeRepo),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ChatApp()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Login with seed account.
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'john_doe',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Chat screen should show the empty state.
    expect(find.text('How can I help you today?'), findsOneWidget);

    // Tap a suggestion chip → message sent.
    await tester.tap(find.text('Help me debug code'));
    // First frame: message added, streaming just started (cursor visible).
    await tester.pump(const Duration(milliseconds: 10));

    // Streaming should start (assistant bubble appears with cursor).
    expect(find.textContaining('▌'), findsOneWidget);

    // Let the stream finish.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    // Assistant response should be visible and streaming done.
    expect(find.textContaining('Pertanyaan yang bagus'), findsOneWidget);
    expect(find.textContaining('▌'), findsNothing);
  });

  testWidgets('Remote new chat: first message creates conversation and '
      'refreshes the list (short chat not stuck)', (tester) async {
    final fakeRepo = _RemoteFakeChatRepository();
    final container = await makeContainer(extraOverrides: [
      chatRepositoryProvider.overrideWithValue(fakeRepo),
      chatDataSourceProvider.overrideWith((ref) => _RemoteFakeDataSource()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ChatApp()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Login with the seed account.
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'john_doe',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Empty state, no conversation yet.
    expect(find.text('How can I help you today?'), findsOneWidget);

    // Send a short message via a suggestion chip (new chat).
    await tester.tap(find.text('Help me debug code'));
    await tester.pump(const Duration(milliseconds: 10));

    // Short stream may already be streaming or done; either way the user
    // message must be present and the assistant must eventually complete.
    var chat = container.read(chatControllerProvider);
    expect(chat.messages.length, 2);

    // Let the short stream finish.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Response is visible and completed (no stuck empty chat).
    expect(find.textContaining('Jawaban singkat'), findsOneWidget);
    chat = container.read(chatControllerProvider);
    expect(chat.isStreaming, isFalse);
    expect(chat.messages.last.content, 'Jawaban singkat.');
    expect(chat.messages.last.status, MessageStatus.completed);

    // The conversation list was refreshed and a conversation now exists.
    expect(chat.conversations.length, 1);
    expect(chat.currentConversationId, 'conv_1');
  });
}
