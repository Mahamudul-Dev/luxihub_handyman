import 'package:luxihub_handyman/features/wallet/domain/entities/wallet.dart';

class WalletModel {
  final String id;
  final double balance;
  final String? stripeAccountId;
  final bool stripePayoutsEnabled;
  final double platformFeePercent;

  const WalletModel({
    required this.id,
    required this.balance,
    this.stripeAccountId,
    this.stripePayoutsEnabled = false,
    this.platformFeePercent = 10.0,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id'] as String,
        balance: (json['balance'] as num).toDouble(),
        stripeAccountId: json['stripe_account_id'] as String?,
        stripePayoutsEnabled: json['stripe_payouts_enabled'] as bool? ?? false,
        platformFeePercent:
            double.tryParse(json['platform_fee_percent']?.toString() ?? '') ??
                10.0,
      );

  Wallet toEntity() => Wallet(
        id: id,
        balance: balance,
        stripeAccountId: stripeAccountId,
        stripePayoutsEnabled: stripePayoutsEnabled,
        platformFeePercent: platformFeePercent,
      );
}
