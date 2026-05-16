import 'package:luxihub_handyman/features/wallet/domain/entities/wallet.dart';

class WalletModel {
  final String id;
  final double balance;
  final String? stripeAccountId;
  final bool stripePayoutsEnabled;

  const WalletModel({
    required this.id,
    required this.balance,
    this.stripeAccountId,
    this.stripePayoutsEnabled = false,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id'] as String,
        balance: (json['balance'] as num).toDouble(),
        stripeAccountId: json['stripe_account_id'] as String?,
        stripePayoutsEnabled: json['stripe_payouts_enabled'] as bool? ?? false,
      );

  Wallet toEntity() => Wallet(
        id: id,
        balance: balance,
        stripeAccountId: stripeAccountId,
        stripePayoutsEnabled: stripePayoutsEnabled,
      );
}
