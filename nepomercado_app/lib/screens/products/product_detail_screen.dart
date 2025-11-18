// screens/products/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/product.dart';
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
        const SnackBar(
          content: Text('Número de contacto no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final phone = _product.artisanPhone!.replaceAll(RegExp(r'[^\d+]'), '');
    final url = 'https://wa.me/$phone?text=Hola! Me interesa tu producto: ${_product.name}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp'),
          backgroundColor: Colors.red,
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
        title: Text(_product.name),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: _isLiking
                  ? const CircularProgressIndicator()
                  : Icon(
                      _product.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _product.isLiked ? Colors.red : null,
                    ),
              onPressed: _toggleLike,
            ),
        ],
      ),
      body: Column(
        children: [
          // 🔥 CAMBIO: Expanded para que el contenido sea scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Carrusel de imágenes
                  _buildImageCarousel(),
                  
                  // Información del producto
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _product.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${_product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Información de likes
                        if (_product.likeCount > 0)
                          Row(
                            children: [
                              const Icon(Icons.favorite, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${_product.likeCount} ${_product.likeCount == 1 ? ' persona le ha dado me encanta' : ' personas le han dado me encanta'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        
                        const SizedBox(height: 16),
                        Text(
                          'Descripción:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),

                        
                        if (_product.artisanName != null) ...[
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Vendedor:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Tarjeta del vendedor con foto de perfil
                          _buildArtisanCard(),
                          
                          // 🔥 NUEVO: Espacio extra al final para que no quede tapado por el botón
                          const SizedBox(height: 80),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // 🔥 CAMBIO: Botón fijo en la parte inferior
      bottomNavigationBar: _buildWhatsAppButton(),
    );
  }

  // 🔥 NUEVO: Botón de WhatsApp en la parte inferior
  Widget _buildWhatsAppButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
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
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Foto de perfil del vendedor
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: ClipOval(
                child: _product.hasArtisanProfileImage
                    ? CachedNetworkImage(
                        imageUrl: _product.artisanProfileImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Información del vendedor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.artisanName!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (_product.artisanPhone != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _product.artisanPhone!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                              ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Vendedor verificado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
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
    );
  }

  // Carrusel para múltiples imágenes
  Widget _buildImageCarousel() {
    if (_product.imageUrls.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('No hay imágenes disponibles'),
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
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Error al cargar imagen'),
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
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_product.imageUrls.length} imágenes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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