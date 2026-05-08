import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/get_wallet_balance.dart';

class GetStripeOnboardingUrl implements UseCase<String, ProfileIdParams> {
  final WalletRepository repository;
  const GetStripeOnboardingUrl(this.repository);

  @override
  Future<Either<Failure, String>> call(ProfileIdParams params) =>
      repository.getStripeOnboardingUrl(params.profileId);
}
