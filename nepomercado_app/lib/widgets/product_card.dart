import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../screens/profile/vendor_profile_screen.dart'; // 🔥 IMPORTAR PANTALLA DE PERFIL

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onLongPress;
  final bool showLikeButton;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onLike,
    this.onLongPress,
    this.showLikeButton = true,
  }) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isLiking = false;

  // 🔥 NUEVO: Navegar al perfil del vendedor
  void _navigateToVendorProfile() {
    if (widget.product.userId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VendorProfileScreen(userId: widget.product.userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede acceder al perfil del vendedor'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatPrice(double price) {
    final intPrice = price.toInt();

    String priceStr = intPrice.toString();
    String formatted = '';
    int counter = 0;

    for (int i = priceStr.length - 1; i >= 0; i--) {
      counter++;
      formatted = priceStr[i] + formatted;
      if (counter % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }
    return '\$$formatted';
  }

  Future<void> _toggleLike() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Si el usuario no está logueado, mostrar diálogo de registro
    if (authService.currentUser == null) {
      _showLoginDialog();
      return;
    }

    if (_isLiking) return;

    setState(() => _isLiking = true);

    final apiService = ApiService();
    final response = await apiService.toggleLike(widget.product.id);

    setState(() => _isLiking = false);

    if (response.success && response.data != null) {
      // Actualizar el estado local del like
      final newLikeCount = response.data!['likeCount'];
      final isLiked = response.data!['liked'];
      
      // Podrías usar un state manager como Provider para actualizar globalmente
      // Por ahora solo actualizamos localmente
      if (mounted) {
        setState(() {
          widget.product.likeCount = newLikeCount;
          widget.product.isLiked = isLiked;
        });
      }
    }
  }

void _showLoginDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Registro Requerido',
        style: TextStyle(color: Color(0xFF0F4C5C)),
      ),
      content: Text('Debes registrarte para dar "me encanta" a los productos.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/register');
          },
          child: Text(
            'Registrarse',
            style: TextStyle(color: Color(0xFF0F4C5C)),
          ),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.currentUser != null;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12), 
    side: BorderSide(
      color: Color(0xFF3A9188).withOpacity(0.1), 
      width: 1,
    ),
  ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto (primera imagen)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.product.imageUrls.isNotEmpty 
                        ? widget.product.imageUrls.first 
                        : '',
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                   placeholder: (context, url) => Container(
                    height: 150,
                    color: Color(0xFFF4EDE4), 
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F4C5C), 
                      ),
                    ),
                  ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: Color(0xFFF4EDE4), 
                      child: Icon(
                        Icons.error_outline,
                        color: Color(0xFF3A9188), 
                        size: 40,
                      ),
                    ),
                  ),
                ),
                
              
                if (widget.product.imageUrls.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF0F4C5C).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${widget.product.imageUrls.length - 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                
                if (widget.showLikeButton)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: widget.onLike ?? _toggleLike,
                      child: Material(
                        color: Colors.transparent,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.product.isLiked
                                ? Color(0xFFE9965C).withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              widget.product.isLiked 
                                ? Icons.favorite 
                                : Icons.favorite_border,
                              color: widget.product.isLiked ? Colors.white :  Color(0xFF3A9188),
                              size: 20,
                              key: ValueKey<bool>(widget.product.isLiked),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Información del producto
            Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(12),
      bottomRight: Radius.circular(12),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.product.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF202124), 
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 4),
      Text(
        widget.product.description,
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
          height: 1.4,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatPrice(widget.product.price),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F4C5C), 
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: Color(0xFFE9965C), 
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                widget.product.likeCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B), 
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
                  // Nombre del vendedor clickeable
                  if (widget.product.artisanName != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _navigateToVendorProfile,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Por: ',
                            style: TextStyle(
                              fontSize: 12,
                             color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            widget.product.artisanName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0F4C5C), 
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new,
                            size: 10,
                            color: Color(0xFF0F4C5C),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Mostrar categoría del producto
                  if (widget.product.category != null && widget.product.category != 'otros') ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(widget.product.category!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryDisplayName(widget.product.category!),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Colores de categorías con nueva paleta
Color _getCategoryColor(String category) {
  final colors = {
    'comida': Color(0xFFE9965C), // Coral
    'ropa': Color(0xFF3A9188),   // Verde azulado
    'artesanias': Color(0xFF0F4C5C), // Azul verde oscuro
    'electronica': Color(0xFF64748B), // Gris
    'hogar': Color(0xFF3A9188), // Verde azulado
    'deportes': Color(0xFFE9965C), // Coral
    'libros': Color(0xFF0F4C5C), // Azul verde oscuro
    'joyeria': Color(0xFFE9965C), // Coral
    'salud': Color(0xFF3A9188), // Verde azulado
    'belleza': Color(0xFF0F4C5C), // Azul verde oscuro
    'juguetes': Color(0xFFE9965C), // Coral
    'mascotas': Color(0xFF3A9188), // Verde azulado
  };
  return colors[category] ?? Color(0xFF64748B); 
}
  // Método para obtener nombre display de categoría
  String _getCategoryDisplayName(String category) {
    final names = {
      'comida': 'Comida',
      'ropa': 'Ropa',
      'artesanias': 'Artesanías',
      'electronica': 'Electrónica',
      'hogar': 'Hogar',
      'deportes': 'Deportes',
      'libros': 'Libros',
      'joyeria': 'Joyería',
      'salud': 'Salud',
      'belleza': 'Belleza',
      'juguetes': 'Juguetes',
      'mascotas': 'Mascotas',
      'otros': 'Otros',
    };
    return names[category] ?? category;
  }
}