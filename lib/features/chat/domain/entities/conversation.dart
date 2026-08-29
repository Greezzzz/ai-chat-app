/// A chat conversation.
class Conversation {
  const Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.documentId,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// RAG document bound to this conversation (null when none). Set on the
  /// first message when creating a new chat with a context document.
  final String? documentId;

  Conversation copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? documentId,
    bool clearDocumentId = false,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentId: clearDocumentId
          ? null
          : (documentId ?? this.documentId),
    );
  }
}
