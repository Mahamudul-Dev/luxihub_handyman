class Review {
  final String id;
  final String jobRequestId;
  final String clientId;
  final String providerId;
  final double score;
  final String? comment;
  final String? clientName;
  final String createdAt;
  final List<String> photoUrls;

  const Review({
    required this.id,
    required this.jobRequestId,
    required this.clientId,
    required this.providerId,
    required this.score,
    this.comment,
    this.clientName,
    required this.createdAt,
    this.photoUrls = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        jobRequestId: json['job_request_id'] as String,
        clientId: json['client_id'] as String,
        providerId: json['provider_id'] as String,
        score: double.tryParse(json['score'].toString()) ?? 0.0,
        comment: json['comment'] as String?,
        clientName:
            (json['profiles'] as Map<String, dynamic>?)?['name'] as String?,
        createdAt: json['created_at'] as String,
        photoUrls:
            (json['photo_urls'] as List?)?.cast<String>() ?? const [],
      );
}
