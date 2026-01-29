class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String?  description;
  final String iconName;
  final String?  imageUrl;
  final int displayOrder;
  final bool isActive;
  final String?  parentId;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this. name,
    required this.slug,
    this.description,
    this.iconName = 'category',
    this.imageUrl,
    this.displayOrder = 0,
    this.isActive = true,
    this.parentId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      iconName: json['icon_name'] ?? 'category',
      imageUrl: json['image_url'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      parentId: json['parent_id'],
      createdAt:  json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon_name': iconName,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'is_active': isActive,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? iconName,
    String? imageUrl,
    int? displayOrder,
    bool?  isActive,
    String? parentId,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id:  id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this. slug,
      description: description ??  this.description,
      iconName: iconName ?? this.iconName,
      imageUrl: imageUrl ?? this.imageUrl,
      displayOrder: displayOrder ?? this. displayOrder,
      isActive:  isActive ?? this.isActive,
      parentId: parentId ??  this.parentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Computed properties
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasParent => parentId != null && parentId!.isNotEmpty;

  @override
  String toString() => 'CategoryModel(id: $id, name: $name, slug:  $slug)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}