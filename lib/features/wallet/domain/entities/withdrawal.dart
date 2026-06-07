import 'package:equatable/equatable.dart';

class Withdrawal extends Equatable {
  final String id;
  final String profileId;
  final double amount;
  final String bankName;
  final String accountLast4;
  final String status;
  final String createdAt;
  final double platformFeePercent;
  final double feeAmount;
  final double netAmount;

  const Withdrawal({
    required this.id,
    required this.profileId,
    required this.amount,
    required this.bankName,
    required this.accountLast4,
    required this.status,
    required this.createdAt,
    this.platformFeePercent = 0,
    this.feeAmount = 0,
    this.netAmount = 0,
  });

  @override
  List<Object> get props => [id, status];
}
