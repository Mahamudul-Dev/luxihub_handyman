import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/wallet.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/withdrawal.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final Wallet wallet;
  final List<Withdrawal> withdrawals;

  const WalletLoaded({required this.wallet, required this.withdrawals});

  @override
  List<Object> get props => [wallet, withdrawals];
}

class WithdrawalSuccess extends WalletState {
  final Withdrawal withdrawal;
  const WithdrawalSuccess(this.withdrawal);

  @override
  List<Object> get props => [withdrawal];
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);

  @override
  List<Object> get props => [message];
}
