class ProfessionalModel {
  final String id;
  final String userId;
  final String?  categoryId;
  final String displayName;
  final String profession;
  final String? description;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? avatarUrl;
  final String? coverUrl;
  final String city;
  final String? area;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> services;
  final int experienceYears;
  final Map<String, dynamic> workingHours;
  final String partnerType;
  final String? groupName;
  final int groupSize;
  final String subscriptionPlan;
  final bool isVerified;
  final bool isAvailable;
  final bool isFeatured;
  final double rating;
  final int totalReviews;
  final int searchAppearances;
  final int profileViews;
  final int totalMessages;
  final double responseRate;
  final int?  avgResponseTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfessionalModel({
    required this.id,
    required this. userId,
    this.categoryId,
    required this.displayName,
    required this.profession,
    this.description,
    this.phone,
    this. whatsapp,
    this. email,
    this.avatarUrl,
    this.coverUrl,
    this.city = 'Shillong',
    this.area,
    this.address,
    this.latitude,
    this.longitude,
    this.services = const [],
    this.experienceYears = 0,
    this.workingHours = const {},
    this.partnerType = 'individual',
    this.groupName,
    this.groupSize = 1,
    this.subscriptionPlan = 'free',
    this.isVerified = false,
    this.isAvailable = true,
    this.isFeatured = false,
    this.rating = 0,
    this.totalReviews = 0,
    this. searchAppearances = 0,
    this.profileViews = 0,
    this.totalMessages = 0,
    this.responseRate = 0,
    this.avgResponseTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ??  DateTime.now();

  factory ProfessionalModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalModel(
      id: json['id'] ?? '',
      userId:  json['user_id'] ?? '',
      categoryId: json['category_id'],
      displayName: json['display_name'] ?? '',
      profession: json['profession'] ?? '',
      description:  json['description'],
      phone:  json['phone'],
      whatsapp: json['whatsapp'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      coverUrl: json['cover_url'],
      city: json['city'] ??  'Shillong',
      area: json['area'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      services: json['services'] != null
          ? List<String>. from(json['services'])
          : [],
      experienceYears: json['experience_years'] ?? 0,
      workingHours:  json['working_hours'] ??  {},
      partnerType: json['partner_type'] ?? 'individual',
      groupName: json['group_name'],
      groupSize: json['group_size'] ?? 1,
      subscriptionPlan: json['subscription_plan'] ?? 'free',
      isVerified: json['is_verified'] ?? false,
      isAvailable: json['is_available'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      rating:  (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      searchAppearances: json['search_appearances'] ?? 0,
      profileViews: json['profile_views'] ?? 0,
      totalMessages: json['total_messages'] ?? 0,
      responseRate: (json['response_rate'] ?? 0).toDouble(),
      avgResponseTime: json['avg_response_time'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id':  userId,
      'category_id': categoryId,
      'display_name': displayName,
      'profession': profession,
      'description': description,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'city': city,
      'area': area,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'services': services,
      'experience_years': experienceYears,
      'working_hours': workingHours,
      'partner_type': partnerType,
      'group_name': groupName,
      'group_size':  groupSize,
      'subscription_plan': subscriptionPlan,
      'is_verified': isVerified,
      'is_available': isAvailable,
      'is_featured': isFeatured,
      'rating': rating,
      'total_reviews': totalReviews,
      'search_appearances': searchAppearances,
      'profile_views': profileViews,
      'total_messages': totalMessages,
      'response_rate': responseRate,
      'avg_response_time':  avgResponseTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProfessionalModel copyWith({
    String? id,
    String? userId,
    String?  categoryId,
    String? displayName,
    String? profession,
    String? description,
    String? phone,
    String?  whatsapp,
    String?  email,
    String? avatarUrl,
    String? coverUrl,
    String? city,
    String? area,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? services,
    int? experienceYears,
    Map<String, dynamic>? workingHours,
    String? partnerType,
    String? groupName,
    int? groupSize,
    String? subscriptionPlan,
    bool? isVerified,
    bool? isAvailable,
    bool? isFeatured,
    double? rating,
    int? totalReviews,
    int? searchAppearances,
    int? profileViews,
    int? totalMessages,
    double? responseRate,
    int? avgResponseTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfessionalModel(
      id: id ??  this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this. categoryId,
      displayName:  displayName ?? this.displayName,
      profession: profession ?? this. profession,
      description: description ??  this.description,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ??  this.whatsapp,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ??  this.coverUrl,
      city: city ?? this.city,
      area: area ?? this.area,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      services: services ?? this.services,
      experienceYears:  experienceYears ?? this.experienceYears,
      workingHours: workingHours ??  this.workingHours,
      partnerType: partnerType ?? this.partnerType,
      groupName: groupName ?? this.groupName,
      groupSize: groupSize ?? this.groupSize,
      subscriptionPlan:  subscriptionPlan ?? this.subscriptionPlan,
      isVerified: isVerified ?? this. isVerified,
      isAvailable: isAvailable ?? this. isAvailable,
      isFeatured: isFeatured ??  this.isFeatured,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      searchAppearances: searchAppearances ??  this.searchAppearances,
      profileViews: profileViews ?? this.profileViews,
      totalMessages: totalMessages ?? this.totalMessages,
      responseRate: responseRate ?? this.responseRate,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasWhatsapp => whatsapp != null && whatsapp!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get hasServices => services.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;
  bool get isGroup => partnerType == 'group';
  bool get isPaidPartner => subscriptionPlan != 'free';
  bool get hasRating => rating > 0;
  bool get hasReviews => totalReviews > 0;

  // Alias getters for compatibility
  String get visibleName => displayName;

  String get ratingDisplay => rating.toStringAsFixed(1);
  
  String get experienceDisplay {
    if (experienceYears == 0) return 'New';
    if (experienceYears == 1) return '1 year';
    return '$experienceYears years';
  }

  String get locationDisplay {
    if (area != null && area!.isNotEmpty) {
      return '$area, $city';
    }
    return city;
  }

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return 'P';
  }

  String get responseTimeDisplay {
    if (avgResponseTime == null) return 'N/A';
    if (avgResponseTime! < 60) return '< 1 hour';
    if (avgResponseTime! < 1440) return '< 24 hours';
    return '> 24 hours';
  }

  @override
  String toString() => 'ProfessionalModel(id: $id, displayName: $displayName, profession: $profession)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfessionalModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}