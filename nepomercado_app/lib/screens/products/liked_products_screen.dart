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
        backgroundColor: const Color(0xFFE9965C), 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          category: product.category,
          userId: product.userId,
          artisanName: product.artisanName,
          artisanPhone: product.artisanPhone,
          createdAt: product.createdAt,
          likeCount: product.likeCount,
          isLiked: product.isLiked,
        );
        
        // Si se quitó el like, remover de la lista
        if (!(response.data?['liked'] ?? false)) {
          _likedProducts.removeAt(index);
          
          // Mostrar feedback cuando se remueve de favoritos
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Removido de tus favoritos'),
              backgroundColor: const Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
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
        title: const Text(
          'Mis Favoritos',
          style: TextStyle(
            color: Color(0xFF202124),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F4C5C)),
        foregroundColor: const Color(0xFF0F4C5C),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF3A9188)),
            onPressed: _loadLikedProducts,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EDE4), 
      body: _isLoading
          ? const LoadingIndicator(message: 'Cargando tus favoritos...')
          : _likedProducts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9965C).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            size: 50,
                            color: Color(0xFFE9965C), 
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No tienes productos favoritos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F4C5C), 
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Da "me encanta" a los productos que te gusten para verlos aquí',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B), 
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); 
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A9188), 
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Explorar Productos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLikedProducts,
                  color: const Color(0xFF0F4C5C), 
                  backgroundColor: const Color(0xFFF4EDE4), 
                  child: Column(
                    children: [
                      // Header con contador
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFF3A9188).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Color(0xFFE9965C), 
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_likedProducts.length} producto${_likedProducts.length == 1 ? '' : 's'} favorito${_likedProducts.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F4C5C), 
                              ),
                            ),
                            const Spacer(),
                            if (_likedProducts.isNotEmpty)
                              Text(
                                'Desliza para actualizar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Lista de productos
                      Expanded(
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
                    ],
                  ),
                ),
    );
  }
}