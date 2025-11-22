import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_indicator.dart';
import 'product_detail_screen.dart';
import 'edit_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({Key? key}) : super(key: key);

  @override
  _MyProductsScreenState createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyProducts();
  }

  Future<void> _loadMyProducts() async {
    setState(() => _isLoading = true);

    final response = await _apiService.getMyProducts();

    if (response.success && response.data != null) {
      setState(() {
        _products = response.data!;
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

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF3A9188), 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  Future<void> _toggleLike(Product product, int index) async {
    final response = await _apiService.toggleLike(product.id);
    
    if (response.success) {
      setState(() {
        // Actualizar el producto en la lista
        _products[index] = Product(
          id: product.id,
          name: product.name,
          price: product.price,
          description: product.description,
          imageUrls: product.imageUrls,
          category: product.category,
          userId: product.userId,
          artisanName: product.artisanName,
          artisanPhone: product.artisanPhone,
          artisanProfileImage: product.artisanProfileImage,
          createdAt: product.createdAt,
          likeCount: product.likeCount,
          isLiked: product.isLiked,
        );
      });
    } else {
      _showErrorSnackbar(response.message);
    }
  }

  void _showPopupMenu(Product product, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4C5C).withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      color: Color(0xFF0F4C5C),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Opciones del producto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F4C5C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Opciones
              ListTile(
                leading: Icon(Icons.edit, color: Color(0xFF3A9188)),
                title: Text(
                  'Editar Producto',
                  style: TextStyle(color: Color(0xFF202124)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditProduct(product);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Color(0xFFE9965C)),
                title: Text(
                  'Eliminar Producto',
                  style: TextStyle(color: Color(0xFF202124)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteProduct(product);
                },
              ),
              
              // Botón cancelar
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF0F4C5C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Color(0xFF0F4C5C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditOptions(Product product) {
    _showPopupMenu(product, _products.indexOf(product));
  }

  void _navigateToEditProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _loadMyProducts(); 
      }
    });
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Producto',
          style: TextStyle(color: Color(0xFF0F4C5C)),
        ),
        content: const Text('¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(product);
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: Color(0xFFE9965C)), 
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final response = await _apiService.deleteProduct(product.id);
    
    if (response.success) {
      _showSuccessSnackbar('Producto eliminado exitosamente');
      _loadMyProducts(); 
    } else {
      _showErrorSnackbar(response.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Productos',
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
            onPressed: _loadMyProducts,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EDE4), 
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const LoadingIndicator(message: 'Cargando tus productos...')
            : _products.isEmpty
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
                              color: const Color(0xFF3A9188).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              size: 50,
                              color: Color(0xFF3A9188), 
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No tienes productos publicados',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F4C5C), 
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Comienza a compartir tus productos con la comunidad',
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
                                Navigator.pushNamed(context, '/add-product');
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
                                'Agregar Producto',
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
                    onRefresh: _loadMyProducts,
                    color: const Color(0xFF0F4C5C), 
                    backgroundColor: const Color(0xFFF4EDE4),
                    child: Column(
                      children: [
                        // Header con estadísticas
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
                                Icons.inventory_2,
                                color: Color(0xFF3A9188), 
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_products.length} producto${_products.length == 1 ? '' : 's'} publicado${_products.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F4C5C), 
                                ),
                              ),
                              const Spacer(),
                              if (_products.isNotEmpty)
                                Text(
                                  'Toca ⋮ para opciones',
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
                            padding: const EdgeInsets.all(16),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return _buildProductCardWithMenu(product, index);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProductCardWithMenu(Product product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          ProductCard(
            product: product,
            onTap: () => _navigateToProductDetail(product),
            onLike: () => _toggleLike(product, index),
            onLongPress: () => _showEditOptions(product),
          ),
          
          // Botón de 3 puntos
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _showPopupMenu(product, index),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Color(0xFF0F4C5C), 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}