import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/features/wallet/data/models/wallet_model.dart';
import 'package:luxihub_handyman/features/wallet/data/models/withdrawal_model.dart';

abstract class WalletRemoteDatasource {
  Future<WalletModel> getWalletBalance(String profileId);
  Future<List<WithdrawalModel>> getWithdrawals(String profileId);
  Future<WithdrawalModel> requestWithdrawal({
    required String profileId,
    required double amount,
    required String bankName,
    required String accountLast4,
  });
}

class WalletRemoteDatasourceImpl implements WalletRemoteDatasource {
  final SupabaseClient client;
  const WalletRemoteDatasourceImpl(this.client);

  @override
  Future<WalletModel> getWalletBalance(String profileId) async {
    try {
      final data = await client
          .from('wallet')
          .upsert({'id': profileId, 'balance': 0.0}, onConflict: 'id')
          .select()
          .single();
      return WalletModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<WithdrawalModel>> getWithdrawals(String profileId) async {
    try {
      final data = await client
          .from('withdrawals')
          .select()
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => WithdrawalModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<WithdrawalModel> requestWithdrawal({
    required String profileId,
    required double amount,
    required String bankName,
    required String accountLast4,
  }) async {
    try {
      final data = await client.from('withdrawals').insert({
        'profile_id': profileId,
        'amount': amount,
        'bank_name': bankName,
        'account_last4': accountLast4,
        'status': 'pending',
      }).select().single();
      return WithdrawalModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
