import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/withdrawal.dart';
import 'package:luxihub_handyman/features/wallet/domain/repositories/wallet_repository.dart';

class RequestWithdrawal implements UseCase<Withdrawal, RequestWithdrawalParams> {
  final WalletRepository repository;
  const RequestWithdrawal(this.repository);

  @override
  Future<Either<Failure, Withdrawal>> call(RequestWithdrawalParams params) =>
      repository.requestWithdrawal(
        profileId: params.profileId,
        amount: params.amount,
        bankName: params.bankName,
        accountLast4: params.accountLast4,
        platformFeePercent: params.platformFeePercent,
        feeAmount: params.feeAmount,
        netAmount: params.netAmount,
      );
}

class RequestWithdrawalParams extends Equatable {
  final String profileId;
  final double amount;
  final String bankName;
  final String accountLast4;
  final double platformFeePercent;
  final double feeAmount;
  final double netAmount;

  const RequestWithdrawalParams({
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
