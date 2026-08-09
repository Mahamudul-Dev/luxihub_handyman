import 'package:luxihub_handyman/features/transactions/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.jobId,
    required super.amount,
    required super.currency,
    required super.paymentMethod,
    required super.status,
    required super.category,
    required super.createdAt,
    super.description,
    super.clientName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;
    return TransactionModel(
      id: json['id'] as String,
      jobId: json['job_request_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? 'gbp',
      paymentMethod: (json['payment_method'] as String?) ?? 'stripe',
      status: (json['status'] as String?) ?? 'pending',
      category: (job?['category'] as String?) ?? 'Service',
      description: job?['description'] as String?,
      clientName: client?['name'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
