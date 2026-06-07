import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luxihub_handyman/features/chat/domain/usecases/get_conversations.dart';
import 'package:luxihub_handyman/features/chat/domain/usecases/get_messages.dart';
import 'package:luxihub_handyman/features/chat/domain/usecases/send_message.dart';
import 'package:luxihub_handyman/features/chat/domain/repositories/chat_repository.dart';
import 'package:luxihub_handyman/features/chat/presentation/bloc/chat_event.dart';
import 'package:luxihub_handyman/features/chat/presentation/bloc/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversations getConversations;
  final GetMessages getMessages;
  final SendMessage sendMessage;
  final ChatRepository _repository;

  StreamSubscription? _messagesSubscription;

  ChatBloc({
    required this.getConversations,
    required this.getMessages,
    required this.sendMessage,
    required ChatRepository repository,
  })  : _repository = repository,
        super(const ChatInitial()) {
    on<ConversationsFetchRequested>(_onFetchConversations);
    on<MessagesFetchRequested>(_onFetchMessages);
    on<MessagesWatchStarted>(_onWatchMessages);
    on<MessageSendRequested>(_onSendMessage);
  }

  Future<void> _onFetchConversations(
    ConversationsFetchRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    final result = await getConversations(GetConversationsParams(event.providerId));
    result.fold(
      (f) {
        debugPrint('[Inbox] Fetch conversations FAILED: ${f.message}');
        emit(ChatError(f.message));
      },
      (conversations) {
        for (final c in conversations) {
          debugPrint('[Inbox] conv ${c.id} unreadCount=${c.unreadCount}');
        }
        emit(ConversationsLoaded(conversations));
      },
    );
  }

  Future<void> _onFetchMessages(
    MessagesFetchRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    final result = await getMessages(ConversationIdParams(event.conversationId));
    result.fold(
      (f) => emit(ChatError(f.message)),
      (messages) => emit(MessagesLoaded(messages)),
    );
  }

  Future<void> _onWatchMessages(
    MessagesWatchStarted event,
    Emitter<ChatState> emit,
  ) async {
    await _messagesSubscription?.cancel();
    await emit.forEach(
      _repository.watchMessages(event.conversationId),
      onData: (messages) => MessagesLoaded(messages),
      onError: (_, _) => const ChatError('Failed to load messages'),
    );
  }

  Future<void> _onSendMessage(
    MessageSendRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await sendMessage(SendMessageParams(
      conversationId: event.conversationId,
      senderId: event.senderId,
      text: event.text,
    ));
    result.fold(
      (f) => emit(ChatError(f.message)),
      (_) {},
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
