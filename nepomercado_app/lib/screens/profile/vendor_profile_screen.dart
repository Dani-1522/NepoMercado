
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/category_selector.dart';
import '../products/product_detail_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  final String userId;

  const VendorProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _VendorProfileScreenState createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  
  User? _vendor;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isLoadingProducts = true;
  
  // FILTROS Y BÚSQUEDA
  String _selectedCategory = 'todos';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVendorProfile();
    _loadVendorProducts();
  }

  Future<void> _loadVendorProfile() async {
    try {
      final response = await _userService.getUserProfile(widget.userId);
      
      if (response.success && response.data != null) {
        setState(() {
          _vendor = response.data;
        });
      } else {
        _showErrorSnackbar(response.message);
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar perfil: $e');
    }
  }

  Future<void> _loadVendorProducts() async {
    setState(() => _isLoadingProducts = true);
    
    try {
      final response = await _apiService.getUserProducts(widget.userId);
      
      if (response.success && response.data != null) {
        setState(() {
          _products = response.data!;
          _filteredProducts = _products;
          _isLoading = false;
          _isLoadingProducts = false;
        });
      } else {
        _showErrorSnackbar(response.message);
        setState(() => _isLoadingProducts = false);
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar productos: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final categoryMatch = _selectedCategory == 'todos' || 
                            product.category == _selectedCategory;
        
        final searchMatch = _searchQuery.isEmpty ||
                           product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: const Color(0xFFE9965C), 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE4), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text(
          _vendor?.name ?? 'Perfil del Vendedor',
          style: const TextStyle(
            color: Color(0xFF0F4C5C), 
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF3A9188)), 
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const LoadingIndicator(message: 'Cargando perfil...')
            : _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        // ENCABEZADO DEL PERFIL
        _buildVendorHeader(),
        
        // BARRA DE BÚSQUEDA
        _buildSearchBar(),
        
        // SELECTOR DE CATEGORÍAS
        _buildCategoryFilter(),
        
        // CONTADOR DE RESULTADOS
        _buildResultsCounter(),
        
        //vLISTA DE PRODUCTOS
        _buildProductsList(),
      ],
    );
  }

  Widget _buildVendorHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      color: const Color(0xFFFFFFFF), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF3A9188).withOpacity(0.1), 
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // FOTO DE PERFIL
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF3A9188).withOpacity(0.3), 
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _vendor?.profileImage != null
                    ? CachedNetworkImage(
                        imageUrl: _vendor!.profileImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFF4EDE4), 
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A9188)), 
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildPlaceholderAvatar(),
                      )
                    : _buildPlaceholderAvatar(),
              ),
            ),
            const SizedBox(width: 16),
            
            // INFORMACIÓN DEL VENDEDOR
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _vendor?.name ?? 'Vendedor',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202124), 
                    ),
                  ),
                  if (_vendor?.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: const Color(0xFF3A9188)), 
                        const SizedBox(width: 6),
                        Text(
                          _vendor!.phone!,
                          style: const TextStyle(color: Color(0xFF202124)), 
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${_products.length} productos publicados',
                    style: const TextStyle(
                      color: Color(0xFF3A9188), 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar en los productos...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF3A9188)), 
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF3A9188).withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A9188)),
          ),
          filled: true,
          fillColor: const Color(0xFFFFFFFF), 
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CategorySelector(
        selectedCategory: _selectedCategory,
        onCategoryChanged: _onCategoryChanged,
      ),
    );
  }

  Widget _buildResultsCounter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_filteredProducts.length} producto${_filteredProducts.length != 1 ? 's' : ''}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F4C5C), 
            ),
          ),
          if (_selectedCategory != 'todos' || _searchQuery.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _clearFilters,
              child: Row(
                children: [
                  Icon(Icons.clear, size: 16, color: const Color(0xFFE9965C)), 
                  const SizedBox(width: 4),
                  Text(
                    'Limpiar filtros',
                    style: TextStyle(color: const Color(0xFFE9965C), fontSize: 12), 
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoadingProducts) {
      return const Expanded(
        child: LoadingIndicator(message: 'Cargando productos...'),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2, size: 64, color: const Color(0xFF3A9188)), 
              const SizedBox(height: 16),
              Text(
                _products.isEmpty ? 'No hay productos' : 'No se encontraron productos',
                style: const TextStyle(
                  fontSize: 16, 
                  color: Color(0xFF202124), 
                ),
              ),
              if (_products.isNotEmpty && (_selectedCategory != 'todos' || _searchQuery.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F4C5C), 
                    ),
                    child: const Text('Limpiar filtros'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ProductCard(
              product: product,
              onTap: () => _navigateToProductDetail(product),
              showLikeButton: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: const Color(0xFFF4EDE4), 
      child: Icon(
        Icons.person,
        color: const Color(0xFF3A9188), 
        size: 40,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'todos';
      _searchQuery = '';
    });
    _filteredProducts = _products;
  }
}