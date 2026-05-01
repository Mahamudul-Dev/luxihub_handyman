import 'package:luxihub_handyman/features/chat/domain/entities/conversation.dart';

class ConversationModel {
  final String id;
  final String jobRequestId;
  final String providerId;
  final String clientId;
  final String? clientName;
  final String? jobCategory;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.jobRequestId,
    required this.providerId,
    required this.clientId,
    this.clientName,
    this.jobCategory,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel(
        id: json['id'] as String,
        jobRequestId: json['job_request_id'] as String,
        providerId: json['provider_id'] as String,
        clientId: json['client_id'] as String,
        clientName:
            (json['profiles'] as Map<String, dynamic>?)?['name'] as String?,
        jobCategory:
            (json['job_requests'] as Map<String, dynamic>?)?['category']
                as String?,
        lastMessage: json['last_message'] as String?,
        lastMessageAt: json['last_message_at'] as String?,
        unreadCount: json['unread_count'] as int? ?? 0,
      );

  Conversation toEntity() => Conversation(
        id: id,
        jobRequestId: jobRequestId,
        providerId: providerId,
        clientId: clientId,
        clientName: clientName,
        jobCategory: jobCategory,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
      );
}
