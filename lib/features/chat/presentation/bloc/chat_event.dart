import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ConversationsFetchRequested extends ChatEvent {
  final String providerId;
  const ConversationsFetchRequested(this.providerId);

  @override
  List<Object> get props => [providerId];
}

class MessagesFetchRequested extends ChatEvent {
  final String conversationId;
  const MessagesFetchRequested(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

class MessagesWatchStarted extends ChatEvent {
  final String conversationId;
  const MessagesWatchStarted(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

class MarkAsReadRequested extends ChatEvent {
  final String conversationId;
  const MarkAsReadRequested(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

class MessageSendRequested extends ChatEvent {
  final String conversationId;
  final String senderId;
  final String text;

  const MessageSendRequested({
    required this.conversationId,
    required this.senderId,
    required this.text,
  });

  @override
  List<Object> get props => [conversationId, senderId, text];
}
