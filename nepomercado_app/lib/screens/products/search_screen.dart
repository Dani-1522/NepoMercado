import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';
import '../../models/search_filters.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_indicator.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  SearchFilters _filters = SearchFilters();
  bool _isLoading = false;
  bool _hasMore = true;
  final int _resultsPerPage = 20;

  // Estados para el drawer de filtros
  double _minPrice = 0;
  double _maxPrice = 10000;
  double _currentMinPrice = 0;
  double _currentMaxPrice = 10000;
  String _selectedSort = 'createdAt';

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
  }

  Future<void> _loadInitialProducts() async {
    setState(() => _isLoading = true);
    await _performSearch(resetPagination: true);
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
        
        // Actualizar rangos de precio
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

  void _onSearchChanged(String value) {
    _filters = _filters.copyWith(query: value, page: 1);
    _debouncedSearch();
  }

  void _debouncedSearch() {
    // Cancelar búsqueda anterior
    _searchTimer?.cancel();
    // Programar nueva búsqueda después de 500ms
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(resetPagination: true);
    });
  }

  Timer? _searchTimer;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
    Navigator.pop(context); // Cerrar drawer
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
        title: const Text('Buscar Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDrawer(),
          ),
        ],
      ),
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
                  hintText: 'Buscar productos...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),

            // Indicador de filtros activos
            if (_filters.hasActiveFilters)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Chip(
                      label: const Text('Filtros activos'),
                      backgroundColor: Colors.blue[50],
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
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _clearFilters,
                    ),
                  ],
                ),
              ),

            // Resultados
            Expanded(
              child: _isLoading && _products.isEmpty
                  ? const LoadingIndicator(message: 'Buscando productos...')
                  : _products.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No se encontraron productos',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Intenta con otros términos de búsqueda',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
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

  Widget _buildFilterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.orange[50],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _hasMore
            ? const CircularProgressIndicator()
            : const Text('No hay más productos'),
      ),
    );
  }

  void _showFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: _buildFilterSheet(),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Filtro por precio
          const Text('Rango de Precio', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('\$${_currentMinPrice.toStringAsFixed(0)}'),
              const Spacer(),
              Text('\$${_currentMaxPrice.toStringAsFixed(0)}'),
            ],
          ),
          RangeSlider(
            values: RangeValues(_currentMinPrice, _currentMaxPrice),
            min: _minPrice,
            max: _maxPrice,
            divisions: 20,
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
          const Text('Ordenar por', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedSort,
            isExpanded: true,
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
          const SizedBox(height: 32),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}