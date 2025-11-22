
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/product.dart';
import '../profile/vendor_profile_screen.dart';
import 'image_viewer_screen.dart'; 

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  late Product _product;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  void _navigateToVendorProfile() {
    if (_product.userId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VendorProfileScreen(userId: _product.userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se puede acceder al perfil del vendedor'),
          backgroundColor: const Color(0xFFE9965C), 
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;
    
    setState(() => _isLiking = true);
    
    final response = await _apiService.toggleLike(_product.id);
    
    if (response.success) {
      setState(() {
        _product = Product(
          id: _product.id,
          name: _product.name,
          price: _product.price,
          description: _product.description,
          imageUrls: _product.imageUrls,
          category: _product.category,
          userId: _product.userId,
          artisanName: _product.artisanName,
          artisanPhone: _product.artisanPhone,
          artisanProfileImage: _product.artisanProfileImage,
          createdAt: _product.createdAt,
          likeCount: _product.likeCount,
          isLiked: _product.isLiked,
        );
      });
    }
    
    setState(() => _isLiking = false);
  }

Future<void> _launchWhatsApp() async {
  if (_product.artisanPhone == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Número de contacto no disponible'),
        backgroundColor: const Color(0xFFE9965C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    return;
  }

  final phone = _product.artisanPhone!.replaceAll(RegExp(r'[^\d+]'), '');
  
  final message = '''
🛍️ *SOLICITUD DE PRODUCTO NepoMercado* 🛍️

¡Hola! Vi tu producto en la app y me interesa mucho:

*📦 Producto:* ${_product.name}
*💰 Precio:* \$${_product.price.toStringAsFixed(2)}
*📋 Categoría:* ${_getCategoryDisplayName(_product.category ?? 'otros')}


¿Podrías darme más información sobre este producto y cómo puedo adquirirlo?

¡Gracias! 😊''';

  final encodedMessage = Uri.encodeComponent(message);
  final url = 'https://wa.me/+57$phone?text=$encodedMessage';

  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No se pudo abrir WhatsApp'),
        backgroundColor: const Color(0xFFE9965C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _product.name,
          style: const TextStyle(
            color: Color(0xFF202124),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F4C5C)),
        foregroundColor: const Color(0xFF0F4C5C),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: _isLiking
                  ? const CircularProgressIndicator(
                      color: Color(0xFF0F4C5C), 
                    )
                  : Icon(
                      _product.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _product.isLiked 
                          ? const Color(0xFFE9965C) 
                          : const Color(0xFF3A9188),
                    ),
              onPressed: _toggleLike,
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EDE4), 
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Carrusel de imágenes
                  _buildImageCarousel(),
                  
                  // Información del producto
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F4C5C), 
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '\$${_product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Color(0xFF0F4C5C), 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Información de likes
                        if (_product.likeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9965C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite, color: Color(0xFFE9965C), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${_product.likeCount} ${_product.likeCount == 1 ? 'persona le ha dado me encanta' : 'personas le han dado me encanta'}',
                                  style: const TextStyle(
                                    color: Color(0xFF0F4C5C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 20),
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F4C5C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF202124),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Categoría del producto
                        if (_product.category != null && _product.category != 'otros')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A9188).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF3A9188).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.category, size: 16, color: Color(0xFF3A9188)),
                                const SizedBox(width: 6),
                                Text(
                                  _getCategoryDisplayName(_product.category!),
                                  style: const TextStyle(
                                    color: Color(0xFF0F4C5C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 24),

                        // Información del vendedor
                        if (_product.artisanName != null) ...[
                          const Divider(
                            color: Color(0xFF3A9188),
                            height: 1,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Vendedor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F4C5C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Tarjeta del vendedor con foto de perfil
                          _buildArtisanCard(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildWhatsAppButton(),
    );
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

  // Botón de WhatsApp en la parte inferior
  Widget _buildWhatsAppButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _launchWhatsApp,
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text(
              'Contactar por WhatsApp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A9188), 
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }

  // Widget para mostrar la información del vendedor con foto
  Widget _buildArtisanCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: InkWell(
          onTap: _navigateToVendorProfile,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Foto de perfil del vendedor
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF3A9188), width: 2),
                ),
                child: ClipOval(
                  child: _product.artisanProfileImage != null && _product.artisanProfileImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _product.artisanProfileImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildPlaceholderAvatar(),
                          errorWidget: (context, url, error) => _buildPlaceholderAvatar(),
                        )
                      : _buildPlaceholderAvatar(),
                ),
              ),
              const SizedBox(width: 16),
              
              // Información del vendedor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _product.artisanName!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F4C5C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF3A9188),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_product.artisanPhone != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 16,
                            color: Color(0xFF3A9188),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _product.artisanPhone!,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Color(0xFF3A9188),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ver perfil del vendedor',
                          style: TextStyle(
                            color: Color(0xFF0F4C5C),
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: const Color(0xFFF4EDE4),
      child: const Icon(
        Icons.person,
        color: Color(0xFF3A9188),
        size: 30,
      ),
    );
  }

  // Carrusel para múltiples imágenes
  Widget _buildImageCarousel() {
    if (_product.imageUrls.isEmpty) {
      return Container(
        height: 300,
        color: const Color(0xFFF4EDE4),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Color(0xFF3A9188)),
              const SizedBox(height: 12),
              Text(
                'No hay imágenes disponibles',
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Navegar al visor de imágenes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewerScreen(
              imageUrls: _product.imageUrls,
              initialIndex: 0,
            ),
          ),
        );
      },
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: _product.imageUrls.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: _product.imageUrls[index],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF4EDE4),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F4C5C),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF4EDE4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 50, color: Color(0xFF3A9188)),
                        const SizedBox(height: 12),
                        Text(
                          'Error al cargar imagen',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Indicador de múltiples imágenes
            if (_product.imageUrls.length > 1)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C5C).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_product.imageUrls.length} imágenes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}