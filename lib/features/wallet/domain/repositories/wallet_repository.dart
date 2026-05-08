import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/wallet.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/withdrawal.dart';

abstract class WalletRepository {
  Future<Either<Failure, Wallet>> getWalletBalance(String profileId);
  Future<Either<Failure, List<Withdrawal>>> getWithdrawals(String profileId);
  Future<Either<Failure, Withdrawal>> requestWithdrawal({
    required String profileId,
    required double amount,
    required String bankName,
    required String accountLast4,
  });
  Future<Either<Failure, String>> getStripeOnboardingUrl(String profileId);
}
