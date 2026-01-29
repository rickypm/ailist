class ConversationModel {
  final String id;
  final String userId;
  final String professionalId;
  final DateTime lastMessageAt;
  final String?  lastMessagePreview;
  final int userUnreadCount;
  final int professionalUnreadCount;
  final bool isUnlocked;
  final String status;
  final DateTime createdAt;

  // Optional joined data
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? professionalName;
  final String? professionalAvatar;
  final String?  profession;

  ConversationModel({
    required this.id,
    required this.userId,
    required this.professionalId,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.userUnreadCount = 0,
    this.professionalUnreadCount = 0,
    this.isUnlocked = false,
    this.status = 'active',
    DateTime? createdAt,
    this.otherUserName,
    this.otherUserAvatar,
    this.professionalName,
    this.professionalAvatar,
    this.profession,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Handle nested professional data
    final professional = json['professional'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;

    return ConversationModel(
      id: json['id'] ??  '',
      userId: json['user_id'] ?? '',
      professionalId: json['professional_id'] ?? '',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : DateTime.now(),
      lastMessagePreview:  json['last_message_preview'],
      userUnreadCount: json['user_unread_count'] ?? 0,
      professionalUnreadCount: json['professional_unread_count'] ?? 0,
      isUnlocked:  json['is_unlocked'] ??  false,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ?  DateTime.parse(json['created_at'])
          : DateTime.now(),
      otherUserName:  user? ['name'],
      otherUserAvatar: user?['avatar_url'],
      professionalName:  professional?['display_name'],
      professionalAvatar: professional?['avatar_url'],
      profession: professional?['profession'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'professional_id': professionalId,
      'last_message_at': lastMessageAt.toIso8601String(),
      'last_message_preview':  lastMessagePreview,
      'user_unread_count': userUnreadCount,
      'professional_unread_count': professionalUnreadCount,
      'is_unlocked': isUnlocked,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    String? id,
    String? userId,
    String? professionalId,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    int? userUnreadCount,
    int? professionalUnreadCount,
    bool? isUnlocked,
    String? status,
    DateTime?  createdAt,
    String?  otherUserName,
    String? otherUserAvatar,
    String? professionalName,
    String? professionalAvatar,
    String? profession,
  }) {
    return ConversationModel(
      id: id ??  this.id,
      userId: userId ?? this.userId,
      professionalId: professionalId ??  this.professionalId,
      lastMessageAt: lastMessageAt ??  this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      userUnreadCount:  userUnreadCount ?? this.userUnreadCount,
      professionalUnreadCount: professionalUnreadCount ?? this.professionalUnreadCount,
      isUnlocked: isUnlocked ?? this. isUnlocked,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ??  this.otherUserAvatar,
      professionalName: professionalName ?? this.professionalName,
      professionalAvatar: professionalAvatar ?? this.professionalAvatar,
      profession: profession ?? this.profession,
    );
  }

  // Computed properties
  bool get hasUnreadForUser => userUnreadCount > 0;
  bool get hasUnreadForProfessional => professionalUnreadCount > 0;
  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';
  bool get isBlocked => status == 'blocked';
  bool get hasLastMessage => lastMessagePreview != null && lastMessagePreview!.isNotEmpty;

  int getUnreadCount(bool isPartner) {
    return isPartner ? professionalUnreadCount : userUnreadCount;
  }

  String getDisplayName(bool isPartner) {
    if (isPartner) {
      return otherUserName ?? 'User';
    }
    return professionalName ?? 'Professional';
  }

  String?  getDisplayAvatar(bool isPartner) {
    if (isPartner) {
      return otherUserAvatar;
    }
    return professionalAvatar;
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(lastMessageAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff. inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastMessageAt.day}/${lastMessageAt.month}/${lastMessageAt.year}';
  }

  String? get professionalProfession => profession;

  String? getAvatarUrl(bool isPartner) {
    if (isPartner) {
      return otherUserAvatar;
    }
    return professionalAvatar;
  }

  @override
  String toString() => 'ConversationModel(id: $id, userId: $userId, professionalId:  $professionalId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}