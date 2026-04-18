import 'package:luxihub_handyman/features/wallet/domain/entities/withdrawal.dart';

class WithdrawalModel {
  final String id;
  final String profileId;
  final double amount;
  final String bankName;
  final String accountLast4;
  final String status;
  final String createdAt;

  const WithdrawalModel({
    required this.id,
    required this.profileId,
    required this.amount,
    required this.bankName,
    required this.accountLast4,
    required this.status,
    required this.createdAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) => WithdrawalModel(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        bankName: json['bank_name'] as String,
        accountLast4: json['account_last4'] as String,
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
      );

  Withdrawal toEntity() => Withdrawal(
        id: id,
        profileId: profileId,
        amount: amount,
        bankName: bankName,
        accountLast4: accountLast4,
        status: status,
        createdAt: createdAt,
      );
}
