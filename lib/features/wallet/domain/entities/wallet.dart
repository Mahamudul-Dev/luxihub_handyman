import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String id;
  final double balance;
  final String? stripeAccountId;

  const Wallet({required this.id, required this.balance, this.stripeAccountId});

  @override
  List<Object?> get props => [id, balance, stripeAccountId];
}
