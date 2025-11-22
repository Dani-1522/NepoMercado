import 'package:flutter/material.dart';
import 'package:NepoMercado/screens/products/search_screen.dart';
import 'package:NepoMercado/screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_indicator.dart';
import '../products/add_product_screen.dart';
import '../products/product_detail_screen.dart';
import '../products/my_products_screen.dart';
import '../products/liked_products_screen.dart'; 
import '../auth/forgot_password_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() => _isLoading = true);
      _currentPage = 1;
    }

    final response = await _apiService.getProducts(
      page: _currentPage,
      limit: _limit,
    );

    if (response.success && response.data != null) {
      setState(() {
      final NewProducts = response.data!;
        
        if (loadMore) {
          _products.addAll(NewProducts);
        } else {
          _products = NewProducts;
        }
        _hasMore = response.data!.length == _limit;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showErrorSnackbar(response.message);
    }
  }

  void _loadMoreProducts() {
    if (!_isLoading && _hasMore) {
      _currentPage++;
      _loadProducts(loadMore: true);
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

  void _refreshProducts() {
    _loadProducts();
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorSnackbar('No se pudo abrir WhatsApp');
    }
  }
  // En la clase _HomeScreenState, actualiza el método _toggleLike:
Future<void> _toggleLike(Product product, int index) async {
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
        createdAt: product.createdAt,
        likeCount: product.likeCount,
        isLiked: product.isLiked, 
      );
    });
    
    // Mostrar feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.data?['liked'] == true 
            ? ' Agregado a tus favoritos' 
            : ' Removido de tus favoritos',
        ),
        duration: const Duration(seconds: 1),
            backgroundColor: response.data?['liked'] == true 
      ? Color(0xFF3A9188) 
      : Color(0xFF64748B), 
  ),

    );
  } else {
    _showErrorSnackbar(response.message);
  }
}
  

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.currentUser != null;

    return Scaffold(
       backgroundColor: Color(0xFFF4EDE4),
appBar: AppBar(
  title: const Text(
    'Catálogo',
    style: TextStyle(
      color: Color(0xFF202124), 
      fontWeight: FontWeight.w600,
    ),
  ),
  backgroundColor: Colors.white, 
  elevation: 1, 
  iconTheme: const IconThemeData(color: Color(0xFF0F4C5C)),
    
  actions: [
    IconButton(
     icon: const Icon(Icons.search, color: Color(0xFF3A9188)),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SearchScreen(),
        ),
      ),
    ),
    if (isLoggedIn)
      IconButton(
         icon: const Icon(Icons.add, color: Color(0xFF3A9188)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddProductScreen(),
          ),
        ),
      ),
    IconButton(
       icon: const Icon(Icons.refresh, color: Color(0xFF3A9188)),
      onPressed: _refreshProducts,
    ),
  ],
),

      drawer: _buildDrawer(authService, isLoggedIn),
      body: _isLoading && _products.isEmpty
          ? const LoadingIndicator(message: 'Cargando productos...')
          : _products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Color(0xFF3A9188)),
                      SizedBox(height: 16),
                      Text(
                        'No hay productos disponibles',
                        style: TextStyle(
                fontSize: 16, 
                color: Color(0xFF202124), 
                fontWeight: FontWeight.w500,
              ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sé el primero en publicar un producto',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadProducts(),
                  child: ListView.builder(
                    itemCount: _products.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _products.length) {
                        return _buildLoadMoreIndicator();
                      }
                      return ProductCard(
                        product: _products[index],
                        onTap: () => _navigateToProductDetail(_products[index]),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildLoadMoreIndicator() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Center(
      child: _hasMore
          ? CircularProgressIndicator(color: Color(0xFF0F4C5C)) 
          : Padding(
              padding: const EdgeInsets.all(16.0),
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
  Widget _buildDrawer(AuthService authService, bool isLoggedIn) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
DrawerHeader(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0F4C5C), 
        Color(0xFF3A9188), 
      ],
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      const Text(
        'Nepo Mercado',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22, 
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      if (isLoggedIn)
        Text(
          'Hola, ${authService.currentUser!.name}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14, 
          ),
        )
      else
        const Text(
          'Bienvenido',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
    ],
  ),
),
          

          // Sección para usuarios logueados
          if (isLoggedIn) ...[
            // Productos likeados
            ListTile(
  leading: Icon(Icons.favorite, color: Color(0xFF0F4C5C)),
   title: Text(
    'Mis Favoritos',
    style: TextStyle(
      color: Color(0xFF202124), 
      fontWeight: FontWeight.w500,
    ),
  ),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LikedProductsScreen(),
      ),
    );
  },
),            
            // Mis productos
            ListTile(
              leading: const Icon(Icons.inventory,color: Color(0xFF0F4C5C)),
              title: const Text(
                'Mis Productos'
                ,
                style: TextStyle(
                  color: Color(0xFF202124),   
                  fontWeight: FontWeight.w500,
                ),
              ),          
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyProductsScreen(),
                  ),
                );
              },
            ),
            
            // Agregar producto
            ListTile(
              leading: const Icon(Icons.add_circle,color: Color(0xFF0F4C5C)),
              title: const Text('Agregar Producto',
                style: TextStyle(
                  color: Color(0xFF202124), 
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                );
              },
            ),

              ListTile(
              leading: const Icon(Icons.person,color: Color(0xFF0F4C5C)),
              title: const Text('Mi perfil ',
                style: TextStyle(
                  color: Color(0xFF202124), 
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                   MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            
            const Divider(),
          ],
          
          // Sección de cuenta
          if (isLoggedIn)
            // Cerrar sesión
            ListTile(
              leading: const Icon(Icons.logout,color: Color(0xFFE9965C)),
              title: const Text('Cerrar Sesión',
                style: TextStyle(
                  color: Color(0xFFE9965C), 
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(authService);
              },
            )
          else
            // Iniciar sesión/Registrarse
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.login, color: Color(0xFF0F4C5C)),
                  title: const Text('Iniciar Sesión',
                    style: TextStyle(
                      color: Color(0xFF202124), 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add, color: Color(0xFF0F4C5C)),
                  title: const Text('Registrarse',
                    style: TextStyle(
                      color: Color(0xFF202124), 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                ),
                // Opción de recuperación de contraseña
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),

          // Información de la app
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
