import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/transactions/data/datasources/transactions_remote_datasource.dart';
import 'package:luxihub_handyman/features/transactions/domain/entities/transaction.dart';
import 'package:luxihub_handyman/features/transactions/domain/repositories/transactions_repository.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionsRemoteDatasource datasource;
  const TransactionsRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions(String providerId) async {
    try {
      final models = await datasource.getTransactions(providerId);
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> getInvoicePdf(String transactionId) async {
    try {
      final bytes = await datasource.getInvoicePdf(transactionId);
      return Right(bytes);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
