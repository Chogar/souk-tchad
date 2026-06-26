import 'user_model.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.content,
    required this.sender,
    required this.createdAt,
    this.conversationId,
  });

  final String id;
  final String content;
  final UserModel sender;
  final DateTime createdAt;
  final String? conversationId;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: UserModel.fromJson(json['sender'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      conversationId: json['conversationId'] as String?,
    );
  }
}
