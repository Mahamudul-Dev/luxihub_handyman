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
  Future<String> getStripeOnboardingUrl(String profileId);
}

class WalletRemoteDatasourceImpl implements WalletRemoteDatasource {
  final SupabaseClient client;
  const WalletRemoteDatasourceImpl(this.client);

  @override
  Future<WalletModel> getWalletBalance(String profileId) async {
    try {
      final walletData = await client
          .from('wallet')
          .upsert({'id': profileId, 'balance': 0.0}, onConflict: 'id')
          .select()
          .single();
      final profileData = await client
          .from('profiles')
          .select('stripe_account_id')
          .eq('id', profileId)
          .single();
      return WalletModel.fromJson({
        ...walletData,
        'stripe_account_id': profileData['stripe_account_id'],
      });
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

  @override
  Future<String> getStripeOnboardingUrl(String profileId) async {
    try {
      final response = await client.functions.invoke(
        'create-connect-account',
        body: {'profile_id': profileId},
      );
      if (response.data == null) throw Exception('Empty response from Edge Function');
      final url = (response.data as Map<String, dynamic>)['url'] as String?;
      if (url == null) throw Exception('No URL in Edge Function response');
      return url;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
