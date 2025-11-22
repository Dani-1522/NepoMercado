class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> imageUrls;
  final String category;

  final String userId;
  final String? artisanName;
  final String? artisanPhone;
   final String? artisanProfileImage;
  final DateTime createdAt;

  int likeCount;
  bool isLiked;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.category,
    required this.userId,
    this.artisanName,
    this.artisanPhone,
    this.artisanProfileImage,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
   
    String userId = '';
    String? artisanName;
    String? artisanPhone;
    String? artisanProfileImage;

    if (json['userId'] is String) {
      userId = json['userId'] ?? '';
    } else if (json['userId'] is Map<String, dynamic>) {
      final userMap = json['userId'] as Map<String, dynamic>;
      userId = userMap['_id']?.toString() ?? ''; 
      artisanName = userMap['name']?.toString();
      artisanPhone = userMap['phone']?.toString();
      artisanProfileImage = userMap['profileImage']; 
    }

  
    return Product(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '', 
      name: json['name']?.toString() ?? 'Sin nombre', 
      price: (json['price'] ?? 0).toDouble(),
      description: json['description']?.toString() ?? 'Sin descripción', 
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'].map((url) => url?.toString() ?? '')) 
          : <String>[],
       category: json['category'] ?? 'otros',
      userId: userId,
      artisanName: artisanName,
      artisanPhone: artisanPhone,
      artisanProfileImage: artisanProfileImage,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now() 
          : DateTime.now(),

      likeCount: (json['likeCount'] ?? 0).toInt(),
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
      "category": category,
      "userId": userId,  
      "artisanName": artisanName,
      "artisanPhone": artisanPhone,
      "artisanProfileImage": artisanProfileImage,
      "createdAt": createdAt.toIso8601String(),
      "likeCount": likeCount,
      "isLiked": isLiked,
    };
  }

  // Método útil para saber si tenemos información completa del Vendedor
  bool get hasArtisanDetails => artisanName != null && artisanPhone != null;
   bool get hasArtisanProfileImage => artisanProfileImage != null && artisanProfileImage!.isNotEmpty;
}