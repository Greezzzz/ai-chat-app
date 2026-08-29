import '../../domain/entities/conversation.dart';

/// Data-layer representation of a conversation.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.documentId,
  });

  factory ConversationModel.fromJson(Map<dynamic, dynamic> json) =>
      ConversationModel(
        id: json['id'].toString(),
        userId: (json['userId'] ?? json['user_id']).toString(),
        title: json['title'] as String? ?? 'New Chat',
        createdAt: DateTime.parse(json['createdAt'] as String? ??
            json['created_at'] as String),
        updatedAt: DateTime.parse(
            json['updatedAt'] as String? ?? json['created_at'] as String),
        documentId: json['documentId']?.toString() ??
            json['document_id']?.toString(),
      );

  factory ConversationModel.fromEntity(Conversation c) => ConversationModel(
        id: c.id,
        userId: c.userId,
        title: c.title,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
        documentId: c.documentId,
      );

  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? documentId;

  Conversation toEntity() => Conversation(
        id: id,
        userId: userId,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        documentId: documentId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (documentId != null) 'documentId': documentId,
      };
}
