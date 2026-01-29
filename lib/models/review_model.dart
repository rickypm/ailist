class ReviewModel {
  final String id;
  final String userId;
  final String? professionalId;
  final String? shopId;
  final int rating;
  final String? comment;
  final bool isVerified;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined data
  final String? userName;
  final String? userAvatar;

  ReviewModel({
    required this.id,
    required this.userId,
    this.professionalId,
    this.shopId,
    required this.rating,
    this.comment,
    this.isVerified = false,
    this.isVisible = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userName,
    this.userAvatar,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      professionalId: json['professional_id'],
      shopId: json['shop_id'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      isVerified: json['is_verified'] ?? false,
      isVisible: json['is_visible'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      userName: json['users']?['name'] ?? json['user_name'],
      userAvatar: json['users']?['avatar_url'] ?? json['user_avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'professional_id': professionalId,
      'shop_id': shopId,
      'rating': rating,
      'comment': comment,
      'is_verified': isVerified,
      'is_visible': isVisible,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}