class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // general, job_update, payment, system
  final String targetType;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetType,
    this.data,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationItem.fromJson(
      Map<String, dynamic> json, DateTime lastReadAt) {
    final createdAt =
        DateTime.parse(json['created_at'] as String).toLocal();
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String? ?? 'general',
      targetType: json['target_type'] as String? ?? 'all',
      data: json['data'] as Map<String, dynamic>?,
      createdAt: createdAt,
      isRead: !createdAt.isAfter(lastReadAt),
    );
  }
}
