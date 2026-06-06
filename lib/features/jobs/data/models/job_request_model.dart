import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';

class JobRequestModel {
  final String id;
  final String clientId;
  final String? clientName;
  final String? providerId;
  final String category;
  final String description;
  final String status;
  final double clientLat;
  final double clientLng;
  final String postedAt;
  final String? completedAt;
  final List<String> attachmentPaths;

  const JobRequestModel({
    required this.id,
    required this.clientId,
    this.clientName,
    this.providerId,
    required this.category,
    required this.description,
    required this.status,
    required this.clientLat,
    required this.clientLng,
    required this.postedAt,
    this.completedAt,
    this.attachmentPaths = const [],
  });

  factory JobRequestModel.fromJson(Map<String, dynamic> json) => JobRequestModel(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        clientName: (json['profiles'] as Map<String, dynamic>?)?['name'] as String?,
        providerId: json['provider_id'] as String?,
        category: json['category'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        clientLat: (json['client_lat'] as num).toDouble(),
        clientLng: (json['client_lng'] as num).toDouble(),
        postedAt: json['posted_at'] as String,
        completedAt: json['completed_at'] as String?,
        attachmentPaths: (json['job_attachments'] as List<dynamic>?)
                ?.map((e) => e['storage_path'] as String)
                .toList() ??
            [],
      );

  JobRequest toEntity() => JobRequest(
        id: id,
        clientId: clientId,
        clientName: clientName,
        providerId: providerId,
        category: category,
        description: description,
        status: status,
        clientLat: clientLat,
        clientLng: clientLng,
        postedAt: postedAt,
        completedAt: completedAt,
        attachmentPaths: attachmentPaths,
      );
}
