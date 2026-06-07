import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/conversation.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/message.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<Conversation>>> getConversations(String providerId);
  Future<Either<Failure, List<Message>>> getMessages(String conversationId);
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });
  Stream<List<Message>> watchMessages(String conversationId);
  Future<Either<Failure, void>> markAsRead(String conversationId);
}
