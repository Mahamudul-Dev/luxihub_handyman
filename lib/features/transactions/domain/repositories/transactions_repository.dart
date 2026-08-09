import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/transactions/domain/entities/transaction.dart';

abstract interface class TransactionsRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions(String providerId);
  Future<Either<Failure, Uint8List>> getInvoicePdf(String transactionId);
}
