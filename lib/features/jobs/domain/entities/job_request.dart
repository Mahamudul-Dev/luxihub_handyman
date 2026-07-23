import 'package:equatable/equatable.dart';

class JobRequest extends Equatable {
  final String id;
  final String clientId;
  final String? clientName;
  final String? providerId;
  final String category;
  final String description;
  final String status;
  final double clientLat;
  final double clientLng;
  final double? offerPrice;
  final String postedAt;
  final String? completedAt;
  final List<String> attachmentPaths;

  const JobRequest({
    required this.id,
    required this.clientId,
    this.clientName,
    this.providerId,
    required this.category,
    required this.description,
    required this.status,
    required this.clientLat,
    required this.clientLng,
    this.offerPrice,
    required this.postedAt,
    this.completedAt,
    this.attachmentPaths = const [],
  });

  @override
  List<Object?> get props => [id, status];
}
