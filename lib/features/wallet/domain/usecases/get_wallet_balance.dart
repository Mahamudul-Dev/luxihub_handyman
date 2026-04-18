import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/wallet.dart';
import 'package:luxihub_handyman/features/wallet/domain/repositories/wallet_repository.dart';

class GetWalletBalance implements UseCase<Wallet, ProfileIdParams> {
  final WalletRepository repository;
  const GetWalletBalance(this.repository);

  @override
  Future<Either<Failure, Wallet>> call(ProfileIdParams params) =>
      repository.getWalletBalance(params.profileId);
}

class ProfileIdParams extends Equatable {
  final String profileId;
  const ProfileIdParams(this.profileId);

  @override
  List<Object> get props => [profileId];
}
