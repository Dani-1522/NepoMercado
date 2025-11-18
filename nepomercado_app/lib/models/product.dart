class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> imageUrls;

  final Map<String, dynamic> userId;  // <--- CAMBIO IMPORTANTE

  final String? artisanName;
  final String? artisanPhone;
  final DateTime createdAt;

  int likeCount;
  bool isLiked;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.userId,   // <--- ahora requerido
    this.artisanName,
    this.artisanPhone,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      
      userId: json['userId'] ?? {},   // <--- now a Map
      
      artisanName: json['userId']?['name'],     // opcional
      artisanPhone: json['userId']?['phone'],   // opcional

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),

      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "price": price,
      "description": description,
      "imageUrls": imageUrls,
      "userId": userId,  
      "artisanName": artisanName,
      "artisanPhone": artisanPhone,
      "createdAt": createdAt.toIso8601String(),
      "likeCount": likeCount,
      "isLiked": isLiked,
    };
  }
}
