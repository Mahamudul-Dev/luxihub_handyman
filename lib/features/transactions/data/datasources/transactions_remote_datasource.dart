import 'dart:typed_data';

import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/features/transactions/data/models/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class TransactionsRemoteDatasource {
  Future<List<TransactionModel>> getTransactions(String providerId);
  Future<Uint8List> getInvoicePdf(String transactionId);
}

class TransactionsRemoteDatasourceImpl implements TransactionsRemoteDatasource {
  final SupabaseClient client;
  const TransactionsRemoteDatasourceImpl(this.client);

  @override
  Future<List<TransactionModel>> getTransactions(String providerId) async {
    try {
      final rows = await client
          .from('transactions')
          .select('*')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false) as List;

      if (rows.isEmpty) return [];

      // Batch-join job_requests (category/description) and client names
      // manually — these tables aren't confirmed to have named FK constraints
      // PostgREST could use for a `.select('*, job_requests(...)')` embed.
      final jobIds = rows.map((r) => r['job_request_id'] as String).toSet().toList();
      final clientIds = rows.map((r) => r['client_id'] as String).whereType<String>().toSet().toList();

      final jobsById = <String, Map<String, dynamic>>{};
      if (jobIds.isNotEmpty) {
        final jobs = await client
            .from('job_requests')
            .select('id, category, description, completed_at')
            .inFilter('id', jobIds) as List;
        for (final j in jobs) {
          jobsById[j['id'] as String] = j as Map<String, dynamic>;
        }
      }

      final clientsById = <String, Map<String, dynamic>>{};
      if (clientIds.isNotEmpty) {
        final clients = await client
            .from('profiles')
            .select('id, name')
            .inFilter('id', clientIds) as List;
        for (final c in clients) {
          clientsById[c['id'] as String] = c as Map<String, dynamic>;
        }
      }

      return rows.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        map['job'] = jobsById[map['job_request_id']];
        map['client'] = clientsById[map['client_id']];
        return TransactionModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Uint8List> getInvoicePdf(String transactionId) async {
    try {
      final res = await client.functions.invoke(
        'generate-invoice',
        body: {'transactionId': transactionId},
      );

      final data = res.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      throw ServerException('Unexpected invoice response (${data.runtimeType})');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
