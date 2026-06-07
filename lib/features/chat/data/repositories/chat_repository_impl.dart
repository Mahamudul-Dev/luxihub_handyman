import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/conversation.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/message.dart';
import 'package:luxihub_handyman/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource datasource;
  const ChatRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<Conversation>>> getConversations(String providerId) async {
    try {
      final models = await datasource.getConversations(providerId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(String conversationId) async {
    try {
      final models = await datasource.getMessages(conversationId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    try {
      final model = await datasource.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        text: text,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return datasource
        .watchMessages(conversationId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Either<Failure, void>> markAsRead(String conversationId) async {
    try {
      await datasource.markAsRead(conversationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
