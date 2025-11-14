import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_indicator.dart';
import 'product_detail_screen.dart';

class LikedProductsScreen extends StatefulWidget {
  const LikedProductsScreen({Key? key}) : super(key: key);

  @override
  _LikedProductsScreenState createState() => _LikedProductsScreenState();
}

class _LikedProductsScreenState extends State<LikedProductsScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _likedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedProducts();
  }

  Future<void> _loadLikedProducts() async {
    setState(() => _isLoading = true);

    final response = await _apiService.getLikedProducts();

    if (response.success && response.data != null) {
      setState(() {
        _likedProducts = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showErrorSnackbar(response.message);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _toggleLike(Product product, int index) async {
    final response = await _apiService.toggleLike(product.id);
    
    if (response.success) {
      setState(() {
        // Actualizar el producto en la lista
        _likedProducts[index] = Product(
          id: product.id,
          name: product.name,
          price: product.price,
          description: product.description,
          imageUrls: product.imageUrls,
          userId: product.userId,
          artisanName: product.artisanName,
          artisanPhone: product.artisanPhone,
          createdAt: product.createdAt,
          likes: product.likes,
          likeCount: response.data?['likeCount'] ?? product.likeCount,
          isLiked: response.data?['liked'] ?? false,
        );
        
        // Si se quitó el like, remover de la lista
        if (!(response.data?['liked'] ?? false)) {
          _likedProducts.removeAt(index);
        }
      });
    } else {
      _showErrorSnackbar(response.message);
    }
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos que te Gustan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLikedProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Cargando tus favoritos...')
          : _likedProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tienes productos favoritos',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Da "me encanta" a los productos que te gusten',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLikedProducts,
                  child: ListView.builder(
                    itemCount: _likedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _likedProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => _navigateToProductDetail(product),
                        onLike: () => _toggleLike(product, index),
                        showLikeButton: true,
                      );
                    },
                  ),
                ),
    );
  }
}