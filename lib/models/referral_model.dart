class ReferralModel {
  final String id;
  final String referrerId;
  final String refereeId;
  final String referralCode;
  final String status;
  final String?  referrerRewardType;
  final double referrerRewardAmount;
  final String? refereeRewardType;
  final double refereeRewardAmount;
  final DateTime? referrerRewardedAt;
  final DateTime? refereeRewardedAt;
  final DateTime createdAt;

  // Joined data
  final String? referrerName;
  final String? referrerEmail;
  final String? refereeName;
  final String? refereeEmail;

  ReferralModel({
    required this.id,
    required this.referrerId,
    required this.refereeId,
    required this.referralCode,
    required this.status,
    this.referrerRewardType,
    required this.referrerRewardAmount,
    this. refereeRewardType,
    required this.refereeRewardAmount,
    this.referrerRewardedAt,
    this. refereeRewardedAt,
    required this.createdAt,
    this.referrerName,
    this.referrerEmail,
    this.refereeName,
    this.refereeEmail,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'] ??  '',
      referrerId: json['referrer_id'] ?? '',
      refereeId: json['referee_id'] ?? '',
      referralCode: json['referral_code'] ?? '',
      status: json['status'] ?? 'pending',
      referrerRewardType: json['referrer_reward_type'],
      referrerRewardAmount: (json['referrer_reward_amount'] ??  0).toDouble(),
      refereeRewardType: json['referee_reward_type'],
      refereeRewardAmount: (json['referee_reward_amount'] ?? 0).toDouble(),
      referrerRewardedAt: json['referrer_rewarded_at'] != null
          ? DateTime.parse(json['referrer_rewarded_at'])
          : null,
      refereeRewardedAt: json['referee_rewarded_at'] != null
          ? DateTime.parse(json['referee_rewarded_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      referrerName: json['referrer_name'] ?? json['users']?['name'],
      referrerEmail: json['referrer_email'] ?? json['users']?['email'],
      refereeName:  json['referee_name'],
      refereeEmail: json['referee_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrer_id': referrerId,
      'referee_id': refereeId,
      'referral_code':  referralCode,
      'status': status,
      'referrer_reward_type': referrerRewardType,
      'referrer_reward_amount': referrerRewardAmount,
      'referee_reward_type': refereeRewardType,
      'referee_reward_amount': refereeRewardAmount,
      'referrer_rewarded_at': referrerRewardedAt?.toIso8601String(),
      'referee_rewarded_at': refereeRewardedAt?.toIso8601String(),
      'created_at':  createdAt.toIso8601String(),
    };
  }

  bool get isRewarded => status == 'rewarded';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
}

class CouponModel {
  final String id;
  final String code;
  final String?  description;
  final String couponType;
  final double rewardValue;
  final int?  discountPercentage;
  final double minPurchaseAmount;
  final int?  maxUses;
  final int usedCount;
  final int maxUsesPerUser;
  final DateTime?  validFrom;
  final DateTime?  validUntil;
  final bool isActive;
  final DateTime createdAt;

  CouponModel({
    required this.id,
    required this.code,
    this. description,
    required this.couponType,
    required this. rewardValue,
    this. discountPercentage,
    required this.minPurchaseAmount,
    this.maxUses,
    required this.usedCount,
    required this.maxUsesPerUser,
    this.validFrom,
    this. validUntil,
    required this.isActive,
    required this.createdAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? '',
      code: json['code'] ??  '',
      description: json['description'],
      couponType: json['coupon_type'] ?? 'free_unlocks',
      rewardValue: (json['reward_value'] ?? 0).toDouble(),
      discountPercentage: json['discount_percentage'],
      minPurchaseAmount: (json['min_purchase_amount'] ?? 0).toDouble(),
      maxUses: json['max_uses'],
      usedCount: json['used_count'] ?? 0,
      maxUsesPerUser: json['max_uses_per_user'] ?? 1,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'])
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'])
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description':  description,
      'coupon_type': couponType,
      'reward_value': rewardValue,
      'discount_percentage':  discountPercentage,
      'min_purchase_amount': minPurchaseAmount,
      'max_uses': maxUses,
      'max_uses_per_user': maxUsesPerUser,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'is_active':  isActive,
    };
  }

  bool get isValid {
    if (! isActive) return false;
    if (maxUses != null && usedCount >= maxUses!) return false;
    if (validFrom != null && DateTime.now().isBefore(validFrom!)) return false;
    if (validUntil != null && DateTime.now().isAfter(validUntil!)) return false;
    return true;
  }

  String get statusText {
    if (! isActive) return 'Disabled';
    if (maxUses != null && usedCount >= maxUses!) return 'Exhausted';
    if (validUntil != null && DateTime.now().isAfter(validUntil!)) return 'Expired';
    return 'Active';
  }

  String get rewardText {
    switch (couponType) {
      case 'free_unlocks': 
        return '${rewardValue.toInt()} Free Unlocks';
      case 'signup_bonus':
        return '${rewardValue.toInt()} Bonus Unlocks';
      case 'discount':
        return '$discountPercentage% Off';
      case 'subscription_days':
        return '${rewardValue.toInt()} Days Free';
      case 'credits':
        return '₹${rewardValue.toInt()} Credits';
      default: 
        return rewardValue.toString();
    }
  }
}

class RewardHistoryModel {
  final String id;
  final String odId;
  final String rewardType;
  final String rewardSource;
  final String?  sourceId;
  final String? description;
  final int unlocksAwarded;
  final double creditsAwarded;
  final int subscriptionDaysAwarded;
  final DateTime createdAt;

  RewardHistoryModel({
    required this. id,
    required this.odId,
    required this.rewardType,
    required this. rewardSource,
    this. sourceId,
    this.description,
    required this.unlocksAwarded,
    required this.creditsAwarded,
    required this.subscriptionDaysAwarded,
    required this.createdAt,
  });

  factory RewardHistoryModel.fromJson(Map<String, dynamic> json) {
    return RewardHistoryModel(
      id:  json['id'] ?? '',
      odId: json['user_id'] ?? '',
      rewardType: json['reward_type'] ?? '',
      rewardSource: json['reward_source'] ?? '',
      sourceId: json['source_id'],
      description: json['description'],
      unlocksAwarded: json['unlocks_awarded'] ?? 0,
      creditsAwarded: (json['credits_awarded'] ?? 0).toDouble(),
      subscriptionDaysAwarded: json['subscription_days_awarded'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get rewardText {
    if (unlocksAwarded > 0) return '+$unlocksAwarded Unlocks';
    if (creditsAwarded > 0) return '+₹${creditsAwarded.toInt()} Credits';
    if (subscriptionDaysAwarded > 0) return '+$subscriptionDaysAwarded Days';
    return 'Reward';
  }
}