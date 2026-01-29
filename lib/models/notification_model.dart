class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String notificationType;
  final String?  actionType;
  final String? actionId;
  final Map<String, dynamic>? actionData;
  final String? imageUrl;
  final bool isRead;
  final bool isPushed;
  final DateTime?  pushedAt;
  final DateTime?  readAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.notificationType = 'general',
    this.actionType,
    this.actionId,
    this.actionData,
    this.imageUrl,
    this.isRead = false,
    this.isPushed = false,
    this.pushedAt,
    this.readAt,
    this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ??  '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ??  '',
      notificationType: json['notification_type'] ?? 'general',
      actionType: json['action_type'],
      actionId: json['action_id'],
      actionData: json['action_data'],
      imageUrl:  json['image_url'],
      isRead: json['is_read'] ?? false,
      isPushed: json['is_pushed'] ?? false,
      pushedAt: json['pushed_at'] != null ? DateTime.parse(json['pushed_at']) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: json['created_at'] != null
          ?  DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'notification_type': notificationType,
      'action_type': actionType,
      'action_id': actionId,
      'action_data': actionData,
      'image_url': imageUrl,
      'is_read': isRead,
      'is_pushed': isPushed,
      'pushed_at': pushedAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? notificationType,
    String? actionType,
    String? actionId,
    Map<String, dynamic>? actionData,
    String? imageUrl,
    bool?  isRead,
    bool? isPushed,
    DateTime? pushedAt,
    DateTime? readAt,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this. userId,
      title: title ??  this.title,
      body: body ?? this.body,
      notificationType: notificationType ??  this.notificationType,
      actionType: actionType ?? this. actionType,
      actionId:  actionId ?? this.actionId,
      actionData: actionData ??  this.actionData,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      isPushed: isPushed ?? this.isPushed,
      pushedAt: pushedAt ?? this.pushedAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ??  this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Computed properties
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasAction => actionType != null && actionId != null;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  String toString() => 'NotificationModel(id: $id, title: $title)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}