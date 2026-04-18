import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/conversation.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ConversationsLoaded extends ChatState {
  final List<Conversation> conversations;
  const ConversationsLoaded(this.conversations);

  @override
  List<Object> get props => [conversations];
}

class MessagesLoaded extends ChatState {
  final List<Message> messages;
  const MessagesLoaded(this.messages);

  @override
  List<Object> get props => [messages];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}
