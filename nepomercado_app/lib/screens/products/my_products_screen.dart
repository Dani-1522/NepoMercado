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
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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

  // ✅ CORREGIDO: Método para alternar like
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

  // 🔥 NUEVO: Mostrar menu de 3 puntos
  void _showPopupMenu(Product product, int index) {
    showModalBottomSheet(
       context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Producto'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditProduct(product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar Producto'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteProduct(product);
                },
              ),
               const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
            ],
          ),
        ),
      ),
    );
  }
  // 🔥 ACTUALIZADO: Mantener el método existente pero renombrar para claridad
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
        _loadMyProducts(); // Recargar la lista si hubo cambios
      }
    });
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(product);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final response = await _apiService.deleteProduct(product.id);
    
    if (response.success) {
      _showSuccessSnackbar('Producto eliminado exitosamente');
      _loadMyProducts(); // Recargar la lista
    } else {
      _showErrorSnackbar(response.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyProducts,
          ),
        ],
      ),
      body: SafeArea( // 🔥 RESPETA LAS BARRAS DEL SISTEMA
      bottom: true, // 🔥 ESPECIALMENTE IMPORTANTE PARA ANDROID
      child: _isLoading
          ? const LoadingIndicator(message: 'Cargando tus productos...')
          : _products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tienes productos publicados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return _buildProductCardWithMenu(product, index);
                    },
                  ),
                ),
    ),
  );
}

  // 🔥 NUEVO: Widget de tarjeta con menu de 3 puntos
// 🔥 ALTERNATIVA: Si el Stack no funciona, modifica el ProductCard directamente
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
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.more_vert,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}