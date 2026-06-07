import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/wallet.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/withdrawal.dart';
import 'package:luxihub_handyman/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDatasource datasource;
  const WalletRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, Wallet>> getWalletBalance(String profileId) async {
    try {
      final model = await datasource.getWalletBalance(profileId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Withdrawal>>> getWithdrawals(String profileId) async {
    try {
      final models = await datasource.getWithdrawals(profileId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Withdrawal>> requestWithdrawal({
    required String profileId,
    required double amount,
    required String bankName,
    required String accountLast4,
    required double platformFeePercent,
    required double feeAmount,
    required double netAmount,
  }) async {
    try {
      final model = await datasource.requestWithdrawal(
        profileId: profileId,
        amount: amount,
        bankName: bankName,
        accountLast4: accountLast4,
        platformFeePercent: platformFeePercent,
        feeAmount: feeAmount,
        netAmount: netAmount,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> getStripeOnboardingUrl(String profileId) async {
    try {
      final url = await datasource.getStripeOnboardingUrl(profileId);
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
