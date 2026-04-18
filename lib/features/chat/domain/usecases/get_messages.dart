import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/message.dart';
import 'package:luxihub_handyman/features/chat/domain/repositories/chat_repository.dart';

class GetMessages implements UseCase<List<Message>, ConversationIdParams> {
  final ChatRepository repository;
  const GetMessages(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(ConversationIdParams params) =>
      repository.getMessages(params.conversationId);
}

class ConversationIdParams extends Equatable {
  final String conversationId;
  const ConversationIdParams(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}
