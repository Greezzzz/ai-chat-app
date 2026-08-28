import '../../../../core/constants/app_constants.dart';

/// Builds a conversation title from the first user message (PRD §15).
///
/// Simple truncation to [AppConstants.conversationTitleMaxLength] characters.
class ConversationTitleGenerator {
  const ConversationTitleGenerator();

  String fromFirstMessage(String message) {
    final trimmed = message.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return 'New Chat';
    if (trimmed.length <= AppConstants.conversationTitleMaxLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, AppConstants.conversationTitleMaxLength - 1)}…';
  }
}
