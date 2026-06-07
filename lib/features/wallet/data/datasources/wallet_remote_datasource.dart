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
    required double platformFeePercent,
    required double feeAmount,
    required double netAmount,
  });
  Future<String> getStripeOnboardingUrl(String profileId);
}

class WalletRemoteDatasourceImpl implements WalletRemoteDatasource {
  final SupabaseClient client;
  const WalletRemoteDatasourceImpl(this.client);

  @override
  Future<WalletModel> getWalletBalance(String profileId) async {
    try {
      final existing = await client
          .from('wallet')
          .select()
          .eq('id', profileId)
          .maybeSingle();

      final walletData = existing ??
          await client
              .from('wallet')
              .insert({'id': profileId, 'balance': 0.0})
              .select()
              .single();

      final profileData = await client
          .from('profiles')
          .select('stripe_account_id, stripe_payouts_enabled')
          .eq('id', profileId)
          .single();

      // Fetch platform fee from settings table (defaults to 10 if missing)
      double feePercent = 10.0;
      try {
        final feeSetting = await client
            .from('settings')
            .select('value')
            .eq('key', 'platform_fee_percent')
            .maybeSingle();
        if (feeSetting != null) {
          feePercent =
              double.tryParse(feeSetting['value'] as String) ?? 10.0;
        }
      } catch (_) {}

      return WalletModel.fromJson({
        ...walletData,
        'stripe_account_id': profileData['stripe_account_id'],
        'stripe_payouts_enabled': profileData['stripe_payouts_enabled'],
        'platform_fee_percent': feePercent,
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
    required double platformFeePercent,
    required double feeAmount,
    required double netAmount,
  }) async {
    try {
      final data = await client.from('withdrawals').insert({
        'profile_id': profileId,
        'amount': amount,
        'bank_name': bankName,
        'account_last4': accountLast4,
        'status': 'pending',
        'platform_fee_percent': platformFeePercent,
        'fee_amount': feeAmount,
        'net_amount': netAmount,
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
