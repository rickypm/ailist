class ShopModel {
  final String id;
  final String professionalId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final String city;
  final String? address;
  final String? locality;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> openingHours;
  final bool isVerified;
  final bool isActive;
  final bool isFeatured;
  final double rating;
  final int totalReviews;
  final int searchAppearances;
  final int profileViews;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopModel({
    required this.id,
    required this.professionalId,
    required this.name,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.city = 'Shillong',
    this.address,
    this.locality,
    this.latitude,
    this.longitude,
    this.openingHours = const {},
    this.isVerified = false,
    this.isActive = true,
    this.isFeatured = false,
    this.rating = 0,
    this.totalReviews = 0,
    this.searchAppearances = 0,
    this.profileViews = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? '',
      professionalId: json['professional_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logo_url'],
      coverImageUrl: json['cover_image_url'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      email: json['email'],
      website: json['website'],
      city: json['city'] ?? 'Shillong',
      address: json['address'],
      locality: json['locality'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      openingHours: json['opening_hours'] ?? {},
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      searchAppearances: json['search_appearances'] ?? 0,
      profileViews: json['profile_views'] ?? 0,
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
      'professional_id': professionalId,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'cover_image_url': coverImageUrl,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'website': website,
      'city': city,
      'address': address,
      'locality': locality,
      'latitude': latitude,
      'longitude': longitude,
      'opening_hours': openingHours,
      'is_verified': isVerified,
      'is_active': isActive,
      'is_featured': isFeatured,
      'rating': rating,
      'total_reviews': totalReviews,
      'search_appearances': searchAppearances,
      'profile_views': profileViews,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ShopModel copyWith({
    String? id,
    String? professionalId,
    String? name,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? phone,
    String? whatsapp,
    String? email,
    String? website,
    String? city,
    String? address,
    String? locality,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? openingHours,
    bool? isVerified,
    bool? isActive,
    bool? isFeatured,
    double? rating,
    int? totalReviews,
    int? searchAppearances,
    int? profileViews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopModel(
      id: id ?? this.id,
      professionalId: professionalId ?? this.professionalId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      website: website ?? this.website,
      city: city ?? this.city,
      address: address ?? this.address,
      locality: locality ?? this.locality,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingHours: openingHours ?? this.openingHours,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      searchAppearances: searchAppearances ?? this.searchAppearances,
      profileViews: profileViews ?? this.profileViews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;
  bool get hasCover => coverImageUrl != null && coverImageUrl!.isNotEmpty;
  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasWhatsapp => whatsapp != null && whatsapp!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;
  bool get hasAddress => address != null && address!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;
  bool get hasRating => rating > 0;
  bool get hasReviews => totalReviews > 0;

  // Alias getters for compatibility
  String? get area => locality;

  String get ratingDisplay => rating.toStringAsFixed(1);

  String get locationDisplay {
    if (locality != null && locality!.isNotEmpty) {
      return '$locality, $city';
    }
    return city;
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    parts.add(city);
    return parts.join(', ');
  }

  @override
  String toString() => 'ShopModel(id: $id, name: $name, city: $city)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}