import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String jobId;
  final double amount;
  final String currency;
  final String paymentMethod; // 'stripe' | 'cash'
  final String status; // 'pending' | 'completed' | 'failed'
  final String category;
  final String? description;
  final String? clientName;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.jobId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.category,
    required this.createdAt,
    this.description,
    this.clientName,
  });

  @override
  List<Object?> get props => [id, jobId, amount, currency, paymentMethod, status, category, createdAt];
}
