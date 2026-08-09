import 'package:equatable/equatable.dart';

abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object> get props => [];
}

class TransactionsFetchRequested extends TransactionsEvent {
  final String providerId;
  const TransactionsFetchRequested(this.providerId);

  @override
  List<Object> get props => [providerId];
}
