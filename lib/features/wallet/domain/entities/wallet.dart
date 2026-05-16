import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String id;
  final double balance;
  final String? stripeAccountId;
  final bool stripePayoutsEnabled;

  const Wallet({
    required this.id,
    required this.balance,
    this.stripeAccountId,
    this.stripePayoutsEnabled = false,
  });

  @override
  List<Object?> get props => [id, balance, stripeAccountId, stripePayoutsEnabled];
}
