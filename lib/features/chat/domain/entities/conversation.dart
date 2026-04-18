import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String jobRequestId;
  final String providerId;
  final String clientId;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.jobRequestId,
    required this.providerId,
    required this.clientId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [id];
}
