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

  const WithdrawalRequested({
    required this.profileId,
    required this.amount,
    required this.bankName,
    required this.accountLast4,
  });

  @override
  List<Object> get props => [profileId, amount, bankName, accountLast4];
}
