import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/transactions/domain/repositories/transactions_repository.dart';

class GetInvoicePdf implements UseCase<Uint8List, TransactionIdParams> {
  final TransactionsRepository repository;
  const GetInvoicePdf(this.repository);

  @override
  Future<Either<Failure, Uint8List>> call(TransactionIdParams params) =>
      repository.getInvoicePdf(params.transactionId);
}

class TransactionIdParams extends Equatable {
  final String transactionId;
  const TransactionIdParams(this.transactionId);

  @override
  List<Object> get props => [transactionId];
}
