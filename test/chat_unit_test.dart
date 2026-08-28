import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat_app/core/constants/app_constants.dart';
import 'package:chat_app/core/storage/app_database.dart';
import 'package:chat_app/core/storage/session_store.dart';
import 'package:chat_app/features/chat/data/datasources/chat_mock_datasource.dart';
import 'package:chat_app/features/chat/domain/usecases/conversation_title_generator.dart';

void main() {
  group('ConversationTitleGenerator', () {
    const generator = ConversationTitleGenerator();

    test('uses the message as title when short', () {
      expect(
        generator.fromFirstMessage('Apa itu Flutter?'),
        'Apa itu Flutter?',
      );
    });

    test('truncates long messages to 40 chars with ellipsis', () {
      final long =
          'Tolong jelaskan state management di Flutter secara detail dan menyeluruh';
      final title = generator.fromFirstMessage(long);
      expect(title.length, AppConstants.conversationTitleMaxLength);
      expect(title.endsWith('…'), isTrue);
    });

    test('falls back to New Chat for empty input', () {
      expect(generator.fromFirstMessage('   '), 'New Chat');
    });

    test('collapses whitespace', () {
      expect(generator.fromFirstMessage('Apa   itu   Flutter?'),
          'Apa itu Flutter?');
    });
  });

  group('MockChatDataSource streaming', () {
    late AppDatabase db;
    late SessionStore session;

    setUpAll(() async {
      final tempDir = await Directory.systemTemp.createTemp('chat_unit_');
      db = await AppDatabase.init(path: tempDir.path);
      SharedPreferences.setMockInitialValues({});
      session = SessionStore(await SharedPreferences.getInstance());
    });

    test('streams word chunks that join into the full response', () async {
      final ds = MockChatDataSource(db, session, chunkDelay: Duration.zero);

      final chunks = <String>[];
      await for (final chunk in ds.streamChat(
        conversationId: 'conv_x',
        message: 'halo',
      )) {
        chunks.add(chunk);
      }

      expect(chunks.length, greaterThan(1));
      expect(chunks.join(), isNotEmpty);
    });

    test('streams multiple chunks over time (not a single burst)', () async {
      final ds = MockChatDataSource(
        db,
        session,
        chunkDelay: const Duration(milliseconds: 5),
      );

      final received = <String>[];
      final sw = Stopwatch()..start();
      await for (final chunk in ds.streamChat(
        conversationId: 'conv_x',
        message: 'halo',
      )) {
        received.add(chunk);
      }
      sw.stop();

      expect(received.length, greaterThan(3));
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(10));
    });
  });
}
