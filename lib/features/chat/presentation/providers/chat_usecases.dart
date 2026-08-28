import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/usecases/create_conversation.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';

final getConversationsProvider = Provider<GetConversations>(
  (ref) => GetConversations(ref.watch(chatRepositoryProvider)),
);

final getMessagesProvider = Provider<GetMessages>(
  (ref) => GetMessages(ref.watch(chatRepositoryProvider)),
);

final createConversationProvider = Provider<CreateConversation>(
  (ref) => CreateConversation(ref.watch(chatRepositoryProvider)),
);

final sendMessageProvider = Provider<SendMessage>(
  (ref) => SendMessage(ref.watch(chatRepositoryProvider)),
);
