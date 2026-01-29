class ItemModel {
  final String id;
  final String shopId;
  final String? categoryId;
  final String name;
  final String? description;
  final String? imageUrl;
  final double? price;
  final String? priceUnit;
  final String? priceType;
  final int? durationMinutes;
  final List<String> tags;
  final bool isActive;
  final bool isFeatured;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemModel({
    required this.id,
    required this.shopId,
    this.categoryId,
    required this.name,
    this.description,
    this.imageUrl,
    this.price,
    this.priceUnit,
    this.priceType,
    this.durationMinutes,
    this.tags = const [],
    this.isActive = true,
    this.isFeatured = false,
    this.displayOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ??  DateTime.now();

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id:  json['id'] ?? '',
      shopId: json['shop_id'] ?? '',
      categoryId: json['category_id'],
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      price: json['price']?.toDouble(),
      priceUnit: json['price_unit'],
      priceType: json['price_type'],
      durationMinutes: json['duration_minutes'],
      tags: json['tags'] != null ?  List<String>.from(json['tags']) : [],
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      displayOrder: json['display_order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ?  DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'price_unit': priceUnit,
      'price_type': priceType,
      'duration_minutes': durationMinutes,
      'tags': tags,
      'is_active':  isActive,
      'is_featured': isFeatured,
      'display_order': displayOrder,
      'created_at':  createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ItemModel copyWith({
    String? id,
    String? shopId,
    String? categoryId,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    String? priceUnit,
    String? priceType,
    int? durationMinutes,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ??  this.id,
      shopId: shopId ?? this.shopId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ??  this.price,
      priceUnit: priceUnit ?? this. priceUnit,
      priceType: priceType ?? this.priceType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tags:  tags ?? this.tags,
      isActive: isActive ?? this. isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      displayOrder: displayOrder ?? this. displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get hasPrice => price != null && price!  > 0;
  bool get hasTags => tags.isNotEmpty;

  String get priceDisplay {
    if (price == null) return 'Price on request';
    final priceStr = '₹${price! .toStringAsFixed(price!  == price! .roundToDouble() ? 0 : 2)}';
    if (priceUnit != null && priceUnit!.isNotEmpty) {
      return '$priceStr/$priceUnit';
    }
    return priceStr;
  }

  @override
  String toString() => 'ItemModel(id: $id, name: $name, price: $price)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}