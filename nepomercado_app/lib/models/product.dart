class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> imageUrls;
  final String userId;
  final String? artisanName;
  final String? artisanPhone;
  final DateTime createdAt;
  final List<String> likes;
  final int likeCount;
  final bool isLiked;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.userId,
    this.artisanName,
    this.artisanPhone,
    required this.createdAt,
    this.likes = const [],
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []), 
      userId: json['userId'] is String 
          ? json['userId'] 
          : json['userId']?['_id'] ?? '',
      artisanName: json['userId'] is Map 
          ? json['userId']['name'] 
          : null,
      artisanPhone: json['userId'] is Map 
          ? json['userId']['phone'] 
          : null,
      likes: List<String>.from(json['likes'] ?? []),
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'imageUrls': imageUrls,
    };
  }
   Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    List<String>? imageUrls,
    String? userId,
    String? artisanName,
    String? artisanPhone,
    DateTime? createdAt,
    List<String>? likes,
    int? likeCount,
    bool? isLiked,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      userId: userId ?? this.userId,
      artisanName: artisanName ?? this.artisanName,
      artisanPhone: artisanPhone ?? this.artisanPhone,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}