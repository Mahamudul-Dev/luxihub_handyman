import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/conversation.dart';
import 'package:luxihub_handyman/features/chat/domain/repositories/chat_repository.dart';

class GetConversations implements UseCase<List<Conversation>, GetConversationsParams> {
  final ChatRepository repository;
  const GetConversations(this.repository);

  @override
  Future<Either<Failure, List<Conversation>>> call(GetConversationsParams params) =>
      repository.getConversations(params.providerId);
}

class GetConversationsParams extends Equatable {
  final String providerId;
  const GetConversationsParams(this.providerId);

  @override
  List<Object> get props => [providerId];
}
