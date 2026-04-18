import 'package:luxihub_handyman/features/dashboard/domain/entities/earning.dart';

class EarningModel {
  final String id;
  final String clientName;
  final String jobCategory;
  final double amount;
  final String date;

  const EarningModel({
    required this.id,
    required this.clientName,
    required this.jobCategory,
    required this.amount,
    required this.date,
  });

  factory EarningModel.fromJson(Map<String, dynamic> json) {
    return EarningModel(
      id: json['id'] as String,
      clientName: json['client_name'] as String? ?? '',
      jobCategory: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['created_at'] as String? ?? '',
    );
  }

  Earning toEntity() => Earning(
        id: id,
        clientName: clientName,
        jobCategory: jobCategory,
        amount: amount,
        date: date,
      );
}
