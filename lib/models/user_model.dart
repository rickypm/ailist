class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? displayName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String subscriptionPlan;
  final int? unlockBalance;
  final String? city;
  final String? referralCode;
  final int? referralCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.displayName,
    this.phone,
    this.avatarUrl,
    this.role = 'user',
    this.subscriptionPlan = 'free',
    this.unlockBalance,
    this.city,
    this.referralCode,
    this.referralCount,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['display_name'],
      displayName: json['display_name'] ?? json['name'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'user',
      subscriptionPlan: json['subscription_plan'] ?? 'free',
      // FIX: The schema uses 'unlocks_remaining', not 'unlock_balance'
      unlockBalance: json['unlocks_remaining'] ?? json['unlock_balance'] ?? 0,
      city: json['city'],
      referralCode: json['referral_code'],
      referralCount: json['total_referrals'] ?? json['referral_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'display_name': displayName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'subscription_plan': subscriptionPlan,
      'unlocks_remaining': unlockBalance,
      'city': city,
      'referral_code': referralCode,
      'total_referrals': referralCount,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? displayName,
    String? phone,
    String? avatarUrl,
    String? role,
    String? subscriptionPlan,
    int? unlockBalance,
    String? city,
    String? referralCode,
    int? referralCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      unlockBalance: unlockBalance ?? this.unlockBalance,
      city: city ?? this.city,
      referralCode: referralCode ?? this.referralCode,
      referralCount: referralCount ?? this.referralCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isPremium => subscriptionPlan == 'plus' || subscriptionPlan == 'pro';
  bool get isBasic => subscriptionPlan == 'basic';
  bool get isFree => subscriptionPlan == 'free';
  bool get hasUnlocks => (unlockBalance ?? 0) > 0 || (unlockBalance ?? 0) == -1;
  bool get canUnlock => isPremium || hasUnlocks;
  bool get isPartner => role == 'professional' || role == 'partner';
  bool get hasUnlimitedUnlocks => (unlockBalance ?? 0) == -1 || isPremium;
  
  int get unlocksRemaining => unlockBalance ?? 0;
  
  String get displayPlan {
    switch (subscriptionPlan) {
      case 'plus':
        return 'PLUS';
      case 'pro':
        return 'PRO';
      case 'basic':
        return 'BASIC';
      default:
        return 'FREE';
    }
  }
  
  String get displayNameOrEmail => name ?? displayName ?? email.split('@').first;
  
  String get initials {
    final n = name ?? displayName;
    if (n != null && n.isNotEmpty) {
      final parts = n.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return n[0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, plan: $subscriptionPlan, unlocks: $unlockBalance, city: $city)';
  }
}