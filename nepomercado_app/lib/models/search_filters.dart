class SearchFilters {
  final String query;
  final String category;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;
  final String sortOrder;
  final int page;
  final int limit;

  SearchFilters({
    this.query = '',
    this.category = 'all',
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.page = 1,
    this.limit = 20,
  });

  SearchFilters copyWith({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
     'query': query,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    // Solo agregar categoría si no es "todos"
    if (category != 'todos') {
      params['category'] = category;
    }

    if (query.isNotEmpty) params['query'] = query;
    if (category != 'all') params['category'] = category;
    if (minPrice != null) params['minPrice'] = minPrice.toString();
    if (maxPrice != null) params['maxPrice'] = maxPrice.toString();

    return params;
  }

  bool get hasActiveFilters {
    return query.isNotEmpty || 
           category != 'all' || 
           minPrice != null || 
           maxPrice != null;
  }

  @override
  String toString() {
    return 'SearchFilters(query: $query, category: $category, minPrice: $minPrice, maxPrice: $maxPrice, sortBy: $sortBy, sortOrder: $sortOrder)';
  }
}