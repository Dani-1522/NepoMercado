import 'package:flutter/material.dart';
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
import '../products/liked_products_screen.dart'; // ✅ AGREGAR IMPORT
import '../auth/forgot_password_screen.dart'; // ✅ AGREGAR IMPORT

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
        if (loadMore) {
          _products.addAll(response.data!);
        } else {
          _products = response.data!;
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Artesanos'),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
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
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay productos disponibles',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sé el primero en publicar un producto',
                        style: TextStyle(color: Colors.grey),
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
            ? const CircularProgressIndicator()
            : const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No hay más productos',
                  style: TextStyle(color: Colors.grey),
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
          // Header del Drawer
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Artesanos App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (isLoggedIn)
                  Text(
                    'Hola, ${authService.currentUser!.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  )
                else
                  const Text(
                    'Bienvenido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),

          // Sección para usuarios logueados
          if (isLoggedIn) ...[
            // Productos likeados
            ListTile(
  leading: const Icon(Icons.favorite),
  title: const Text('Mis Favoritos'),
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

// Y en las acciones de la app bar, agrega:
if (isLoggedIn)
  IconButton(
    icon: const Icon(Icons.favorite),
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LikedProductsScreen(),
      ),
    ),
  ),
            
            // Mis productos
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Mis Productos'),
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
              leading: const Icon(Icons.add_circle),
              title: const Text('Agregar Producto'),
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
            
            const Divider(),
          ],

          // Sección de cuenta
          if (isLoggedIn)
            // Cerrar sesión
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
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
                  leading: const Icon(Icons.login),
                  title: const Text('Iniciar Sesión'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Registrarse'),
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
