import 'dart:async';

import 'package:NepoMercado/models/user.dart';
import 'package:flutter/material.dart';
import 'package:NepoMercado/widgets/category_selector.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import '../../models/product.dart';
import '../../models/search_filters.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_indicator.dart';
import 'product_detail_screen.dart';
import '../profile/vendor_profile_screen.dart';
import '../../widgets/vendor_result_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  SearchFilters _filters = SearchFilters();
  bool _isLoading = false;
  bool _hasMore = true;
  final int _resultsPerPage = 20;

 
  double _minPrice = 0;
  double _maxPrice = 10000;
  double _currentMinPrice = 0;
  double _currentMaxPrice = 10000;
  String _selectedSort = 'createdAt';

  List<User> _vendors = [];
  List<User> _filteredVendors = [];
  bool _showVendors = false;

  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialProducts() async {
    setState(() => _isLoading = true);
    await _performSearch(resetPagination: true);
  }

  Future<void> _searchVendors(String query) async {
    if (query.isEmpty) {
      setState(() {
        _vendors = [];
        _filteredVendors = [];
        _showVendors = false;
      });
      return;
    }
    try {
      final response = await _userService.searchVendors(query);
      
      if (response.success && response.data != null) {
        setState(() {
          _vendors = response.data!;
          _filteredVendors = _vendors;
          _showVendors = _vendors.isNotEmpty;
        });
      }
    } catch (e) {
      print('💥 Error buscando vendedores: $e');
    }
  }

  void _onSearchChanged(String value) {
    _filters = _filters.copyWith(query: value, page: 1);
    _debouncedSearch();
    _searchVendors(value);
  }

  void _debouncedSearch() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(resetPagination: true);
    });
  }

  Future<void> _performSearch({bool resetPagination = false}) async {
    if (resetPagination) {
      _filters = _filters.copyWith(page: 1);
    }

    setState(() => _isLoading = true);

    final response = await _apiService.searchProducts(_filters);

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      final newProducts = response.data!['products'] as List<Product>;
      final pagination = response.data!['pagination'] as Map<String, dynamic>;

      setState(() {
        if (resetPagination) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }
        _hasMore = _filters.page < pagination['pages'];
        
      
        final filtersData = response.data!['filters'] as Map<String, dynamic>;
        final priceRange = filtersData['priceRange'] as Map<String, dynamic>;
        _minPrice = (priceRange['min'] ?? 0).toDouble();
        _maxPrice = (priceRange['max'] ?? 10000).toDouble();
        _currentMinPrice = _filters.minPrice ?? _minPrice;
        _currentMaxPrice = _filters.maxPrice ?? _maxPrice;
      });
    }
  }

  void _loadMoreProducts() {
    if (!_isLoading && _hasMore) {
      _filters = _filters.copyWith(page: _filters.page + 1);
      _performSearch();
    }
  }

  void _navigateToVendorProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorProfileScreen(userId: userId),
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

  void _toggleLike(Product product, int index) async {
    final response = await _apiService.toggleLike(product.id);
    
    if (response.success) {
      setState(() {
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
    }
  }

  void _applyFilters() {
    _filters = _filters.copyWith(
      minPrice: _currentMinPrice,
      maxPrice: _currentMaxPrice,
      sortBy: _selectedSort,
      page: 1,
    );
    Navigator.pop(context);
    _performSearch(resetPagination: true);
  }

  void _clearFilters() {
    _filters = SearchFilters(query: _filters.query);
    _currentMinPrice = _minPrice;
    _currentMaxPrice = _maxPrice;
    _selectedSort = 'createdAt';
    _performSearch(resetPagination: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buscar Productos y Vendedores',
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
            icon: const Icon(Icons.filter_list, color: Color(0xFF3A9188)),
            onPressed: _showFilterDrawer,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EDE4), 
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar productos o vendedores...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF3A9188)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF3A9188).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0F4C5C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            // Sección de vendedores
            if (_showVendors) _buildVendorsSection(),

            // Selector de categorías
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CategorySelector(
                selectedCategory: _filters.category,
                onCategoryChanged: (category) {
                  setState(() {
                    _filters = _filters.copyWith(category: category, page: 1);
                  });
                  _performSearch(resetPagination: true);
                },
              ),
            ),

            // Indicador de filtros activos
            if (_filters.hasActiveFilters)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A9188).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F4C5C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Filtros activos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F4C5C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_filters.query.isNotEmpty)
                              _buildFilterChip('Buscar: "${_filters.query}"'),
                            if (_filters.minPrice != null)
                              _buildFilterChip('Mín: \$${_filters.minPrice!.toStringAsFixed(0)}'),
                            if (_filters.maxPrice != null)
                              _buildFilterChip('Máx: \$${_filters.maxPrice!.toStringAsFixed(0)}'),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFFE9965C)),
                      onPressed: _clearFilters,
                    ),
                  ],
                ),
              ),

            // Resultados
            Expanded(
              child: _isLoading && _products.isEmpty
                  ? const LoadingIndicator(message: 'Buscando productos...')
                  : _products.isEmpty && _vendors.isEmpty
                      ? _buildEmptyState()
                      : NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent) {
                              _loadMoreProducts();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            itemCount: _products.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _products.length) {
                                return _buildLoadMoreIndicator();
                              }
                              return ProductCard(
                                product: _products[index],
                                onTap: () => _navigateToProductDetail(_products[index]),
                                onLike: () => _toggleLike(_products[index], index),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A9188).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: Color(0xFF3A9188), size: 20),
              const SizedBox(width: 8),
              Text(
                'Emprendedores (${_filteredVendors.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F4C5C),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredVendors.length,
          itemBuilder: (context, index) {
            final vendor = _filteredVendors[index];
            return VendorResultCard(
              vendor: vendor,
              onTap: () => _navigateToVendorProfile(vendor.id),
            );
          },
        ),
        const Divider(
          color: Color(0xFF3A9188),
          height: 1,
          thickness: 0.5,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              child: Icon(
                _searchController.text.isEmpty ? Icons.search : Icons.search_off,
                size: 50,
                color: Color(0xFF3A9188),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isEmpty
                  ? 'Busca productos o emprendedores'
                  : 'No se encontraron resultados',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F4C5C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isEmpty
                  ? 'Encuentra productos únicos y conecta con emprendedores locales'
                  : 'Intenta con otros términos de búsqueda o ajusta los filtros',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE9965C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9965C).withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF0F4C5C),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _hasMore
            ? const CircularProgressIndicator(color: Color(0xFF0F4C5C))
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No hay más productos',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
      ),
    );
  }

  void _showFilterDrawer() {
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
          child: _buildFilterSheet(),
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros de Búsqueda',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F4C5C),
            ),
          ),
          const SizedBox(height: 16),

          // Filtro por precio
          const Text(
            'Rango de Precio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F4C5C),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '\$${_currentMinPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF0F4C5C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '\$${_currentMaxPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF0F4C5C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(_currentMinPrice, _currentMaxPrice),
            min: _minPrice,
            max: _maxPrice,
            divisions: 20,
            activeColor: const Color(0xFF0F4C5C),
            inactiveColor: const Color(0xFF3A9188).withOpacity(0.3),
            labels: RangeLabels(
              '\$${_currentMinPrice.toStringAsFixed(0)}',
              '\$${_currentMaxPrice.toStringAsFixed(0)}',
            ),
            onChanged: (values) {
              setState(() {
                _currentMinPrice = values.start;
                _currentMaxPrice = values.end;
              });
            },
          ),
          const SizedBox(height: 24),

          // Ordenamiento
          const Text(
            'Ordenar por',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F4C5C),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF3A9188).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedSort,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Color(0xFF202124)),
              items: const [
                DropdownMenuItem(value: 'createdAt', child: Text('Más recientes')),
                DropdownMenuItem(value: 'price', child: Text('Precio menor a mayor')),
                DropdownMenuItem(value: 'priceDesc', child: Text('Precio mayor a menor')),
                DropdownMenuItem(value: 'name', child: Text('Nombre A-Z')),
              ],
              onChanged: (value) {
                setState(() => _selectedSort = value!);
              },
            ),
          ),
          const SizedBox(height: 32),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF0F4C5C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Limpiar',
                    style: TextStyle(
                      color: Color(0xFF0F4C5C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A9188),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}