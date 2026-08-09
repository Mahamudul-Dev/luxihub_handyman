import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/transactions/domain/entities/transaction.dart';
import 'package:luxihub_handyman/features/transactions/domain/repositories/transactions_repository.dart';

class GetTransactions implements UseCase<List<Transaction>, ProviderIdParams> {
  final TransactionsRepository repository;
  const GetTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(ProviderIdParams params) =>
      repository.getTransactions(params.providerId);
}

class ProviderIdParams extends Equatable {
  final String providerId;
  const ProviderIdParams(this.providerId);

  @override
  List<Object> get props => [providerId];
}
