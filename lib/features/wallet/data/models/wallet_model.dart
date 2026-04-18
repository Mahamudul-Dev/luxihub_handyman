import 'package:luxihub_handyman/features/wallet/domain/entities/wallet.dart';

class WalletModel {
  final String id;
  final double balance;

  const WalletModel({required this.id, required this.balance});

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id'] as String,
        balance: (json['balance'] as num).toDouble(),
      );

  Wallet toEntity() => Wallet(id: id, balance: balance);
}
