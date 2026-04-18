import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/withdrawal.dart';
import 'package:luxihub_handyman/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/get_wallet_balance.dart';

class GetWithdrawals implements UseCase<List<Withdrawal>, ProfileIdParams> {
  final WalletRepository repository;
  const GetWithdrawals(this.repository);

  @override
  Future<Either<Failure, List<Withdrawal>>> call(ProfileIdParams params) =>
      repository.getWithdrawals(params.profileId);
}
