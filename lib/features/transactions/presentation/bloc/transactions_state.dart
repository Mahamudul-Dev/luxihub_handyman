import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/features/transactions/domain/entities/transaction.dart';

abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class TransactionsLoaded extends TransactionsState {
  final List<Transaction> transactions;
  const TransactionsLoaded(this.transactions);

  @override
  List<Object> get props => [transactions];
}

class TransactionsError extends TransactionsState {
  final String message;
  const TransactionsError(this.message);

  @override
  List<Object> get props => [message];
}
