import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String id;
  final double balance;

  const Wallet({required this.id, required this.balance});

  @override
  List<Object> get props => [id, balance];
}
