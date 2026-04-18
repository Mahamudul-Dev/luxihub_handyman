import 'package:luxihub_handyman/features/chat/domain/entities/message.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        text: json['text'] as String,
        createdAt: json['created_at'] as String,
      );

  Message toEntity() => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        createdAt: createdAt,
      );
}
