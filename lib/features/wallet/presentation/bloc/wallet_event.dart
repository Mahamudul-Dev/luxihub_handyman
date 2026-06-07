import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object> get props => [];
}

class WalletFetchRequested extends WalletEvent {
  final String profileId;
  const WalletFetchRequested(this.profileId);

  @override
  List<Object> get props => [profileId];
}

class WithdrawalsFetchRequested extends WalletEvent {
  final String profileId;
  const WithdrawalsFetchRequested(this.profileId);

  @override
  List<Object> get props => [profileId];
}

class WithdrawalRequested extends WalletEvent {
  final String profileId;
  final double amount;
  final String bankName;
  final String accountLast4;
  final double platformFeePercent;
  final double feeAmount;
  final double netAmount;

  const WithdrawalRequested({
    required this.profileId,
    required this.amount,
    required this.bankName,
    required this.accountLast4,
    required this.platformFeePercent,
    required this.feeAmount,
    required this.netAmount,
  });

  @override
  List<Object> get props => [profileId, amount, bankName, accountLast4];
}

class ConnectStripeRequested extends WalletEvent {
  final String profileId;
  const ConnectStripeRequested(this.profileId);

  @override
  List<Object> get props => [profileId];
}
