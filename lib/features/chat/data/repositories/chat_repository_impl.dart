import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/environment.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/conversation_title_generator.dart';
import '../datasources/chat_data_source.dart';
import '../datasources/chat_mock_datasource.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/message_model.dart';

/// Chat repository that orchestrates data source + persistence + streaming.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._dataSource, this._db, this._titleGenerator);

  final ChatDataSource _dataSource;
  final AppDatabase _db;
  final ConversationTitleGenerator _titleGenerator;

  @override
  Future<List<Conversation>> getConversations() {
    return _dataSource.getConversations();
  }

  @override
  Future<Conversation?> getConversation(String id) {
    return _dataSource.getConversation(id);
  }

  @override
  Future<List<Message>> getMessages(String conversationId) {
    return _dataSource.getMessages(conversationId);
  }

  @override
  Future<Conversation> createConversation() {
    return _dataSource.createConversation();
  }

  @override
  Future<void> updateConversation(Conversation conversation) {
    return _dataSource.updateConversation(conversation);
  }

  @override
  Future<String> uploadDocument({
    required String title,
    required String content,
  }) {
    return _dataSource.uploadDocument(title: title, content: content);
  }

  @override
  Stream<String> sendMessage({
    required String? conversationId,
    required String message,
    String? documentId,
  }) async* {
    final now = DateTime.now();
    final local = _dataSource.persistsLocally;

    // Resolve the conversation: create one on the first message (mock mode).
    // In remote mode the backend creates it implicitly on the stream request.
    final convId = conversationId ??
        (local ? (await _dataSource.createConversation()).id : '');

    // Persist the user message (mock mode only).
    if (local) {
      final userMessage = Message(
        id: 'msg_${now.microsecondsSinceEpoch}',
        conversationId: convId,
        role: MessageRole.user,
        content: message,
        createdAt: now,
      );
      await _db.messages.put(
        userMessage.id,
        MessageModel.fromEntity(userMessage).toJson(),
      );

      // Set the title from the first message when it's still a new chat.
      final conv = await _dataSource.getConversation(convId);
      if (conv != null && (conv.title == 'New Chat' || conv.title.isEmpty)) {
        final updated = conv.copyWith(
          title: _titleGenerator.fromFirstMessage(message),
          updatedAt: now,
          documentId: documentId,
        );
        await _dataSource.updateConversation(updated);
      } else if (conv != null) {
        await _dataSource.updateConversation(conv.copyWith(updatedAt: now));
      }
    }

    // Prepare the assistant message and stream chunks into it.
    final assistantMessage = Message(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}_ai',
      conversationId: convId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      status: MessageStatus.streaming,
    );
    if (local) {
      await _db.messages.put(
        assistantMessage.id,
        MessageModel.fromEntity(assistantMessage).toJson(),
      );
    }

    final buffer = StringBuffer();
    try {
      await for (final chunk in _dataSource.streamChat(
        conversationId: convId,
        message: message,
        documentId: documentId,
      )) {
        buffer.write(chunk);
        // Persist incrementally so a crash mid-stream keeps partial content.
        if (local) {
          final partial = assistantMessage.copyWith(
            content: buffer.toString(),
            status: MessageStatus.streaming,
          );
          await _db.messages.put(
            assistantMessage.id,
            MessageModel.fromEntity(partial).toJson(),
          );
        }
        yield chunk;
      }

      if (local) {
        final completed = assistantMessage.copyWith(
          content: buffer.toString(),
          status: MessageStatus.completed,
        );
        await _db.messages.put(
          assistantMessage.id,
          MessageModel.fromEntity(completed).toJson(),
        );
      }
    } catch (e) {
      // Mark the message as errored so the UI can offer retry.
      if (local) {
        final failed = assistantMessage.copyWith(
          content: buffer.isEmpty ? '' : buffer.toString(),
          status: MessageStatus.error,
        );
        await _db.messages.put(
          assistantMessage.id,
          MessageModel.fromEntity(failed).toJson(),
        );
      }
      if (e is AppException) rethrow;
      throw AppException('AI response failed.', code: 'ai');
    }
  }
}

/// Selects the concrete chat data source based on the runtime environment.
final chatDataSourceProvider = Provider<ChatDataSource>((ref) {
  final session = ref.watch(sessionStoreProvider) ??
      (throw StateError('SessionStore not initialized'));
  if (AppEnvironment.isMock) {
    return MockChatDataSource(AppDatabase.instance, session);
  }
  return ChatRemoteDataSource(session);
});

/// The chat repository used across the app.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    ref.watch(chatDataSourceProvider),
    AppDatabase.instance,
    const ConversationTitleGenerator(),
  );
});
