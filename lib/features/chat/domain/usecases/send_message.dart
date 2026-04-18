import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/message.dart';
import 'package:luxihub_handyman/features/chat/domain/repositories/chat_repository.dart';

class SendMessage implements UseCase<Message, SendMessageParams> {
  final ChatRepository repository;
  const SendMessage(this.repository);

  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) =>
      repository.sendMessage(
        conversationId: params.conversationId,
        senderId: params.senderId,
        text: params.text,
      );
}

class SendMessageParams extends Equatable {
  final String conversationId;
  final String senderId;
  final String text;

  const SendMessageParams({
    required this.conversationId,
    required this.senderId,
    required this.text,
  });

  @override
  List<Object> get props => [conversationId, senderId, text];
}
