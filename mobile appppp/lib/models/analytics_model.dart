class UserNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? relatedComplaintId;
  final bool isRead;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedComplaintId,
    this.isRead = false,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    final complaintId =
        (json['complaint_id'] ?? json['related_complaint_id'])?.toString() ??
            '';
    final notificationId = (json['id'] ?? complaintId.isNotEmpty
            ? 'notif_$complaintId'
            : 'notif_${DateTime.now().millisecondsSinceEpoch}')
        .toString();
    final notificationType = (json['type'] ?? 'info').toString();
    final title = (json['title'] ?? '').toString().trim().isNotEmpty
        ? json['title'].toString()
        : _titleFromType(notificationType);
    final isReadValue = json['is_read'] ?? json['read'] ?? false;

    return UserNotification(
      id: notificationId,
      userId: (json['user_id'] ?? '').toString(),
      title: title,
      message: (json['message'] ?? '').toString(),
      type: notificationType,
      relatedComplaintId: complaintId.isNotEmpty ? complaintId : null,
      isRead: isReadValue == true,
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }

  static String _titleFromType(String type) {
    switch (type) {
      case 'status_change':
        return 'Status Updated';
      case 'resolved':
        return 'Resolved';
      case 'message':
        return 'New Message';
      default:
        return 'Update';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_complaint_id': relatedComplaintId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
