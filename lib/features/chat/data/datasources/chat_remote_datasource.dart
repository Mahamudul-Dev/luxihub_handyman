import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/features/chat/data/models/conversation_model.dart';
import 'package:luxihub_handyman/features/chat/data/models/message_model.dart';

abstract class ChatRemoteDatasource {
  Future<List<ConversationModel>> getConversations(String providerId);
  Future<List<MessageModel>> getMessages(String conversationId);
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });
  Stream<List<MessageModel>> watchMessages(String conversationId);
}

class ChatRemoteDatasourceImpl implements ChatRemoteDatasource {
  final SupabaseClient client;
  const ChatRemoteDatasourceImpl(this.client);

  @override
  Future<List<ConversationModel>> getConversations(String providerId) async {
    try {
      final data = await client
          .from('conversations')
          .select('*, profiles!client_id(name), job_requests!job_request_id(category)')
          .eq('provider_id', providerId)
          .order('last_message_at', ascending: false);
      return (data as List).map((e) => ConversationModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final data = await client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return (data as List).map((e) => MessageModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    try {
      final data = await client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'text': text,
      }).select().single();
      return MessageModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
  }
}
