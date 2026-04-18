import 'package:equatable/equatable.dart';

class Earning extends Equatable {
  final String id;
  final String clientName;
  final String jobCategory;
  final double amount;
  final String date;

  const Earning({
    required this.id,
    required this.clientName,
    required this.jobCategory,
    required this.amount,
    required this.date,
  });

  @override
  List<Object> get props => [id];
}
