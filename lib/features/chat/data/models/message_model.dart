import '../../domain/entities/message.dart';

/// Data-layer representation of a chat message.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
  });

  factory MessageModel.fromJson(Map<dynamic, dynamic> json) => MessageModel(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        role: _roleFrom(json['role'] as String),
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: _statusFrom(json['status'] as String? ?? 'completed'),
      );

  factory MessageModel.fromEntity(Message m) => MessageModel(
        id: m.id,
        conversationId: m.conversationId,
        role: m.role,
        content: m.content,
        createdAt: m.createdAt,
        status: m.status,
      );

  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  Message toEntity() => Message(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content,
        createdAt: createdAt,
        status: status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'role': role.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };

  static MessageRole _roleFrom(String v) =>
      MessageRole.values.firstWhere((r) => r.name == v);

  static MessageStatus _statusFrom(String v) =>
      MessageStatus.values.firstWhere((s) => s.name == v);
}
