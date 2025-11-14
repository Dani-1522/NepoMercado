import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/product.dart';

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
          createdAt: _product.createdAt,
          likes: _product.likes,
          likeCount: response.data?['likeCount'] ?? _product.likeCount,
          isLiked: response.data?['liked'] ?? _product.isLiked,
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ MEJORADO: Carrusel de imágenes
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
                  
                  // ✅ NUEVO: Información de likes
                  if (_product.likeCount > 0)
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_product.likeCount} ${_product.likeCount == 1 ? 'persona le da' : 'personas le dan'} me encanta',
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

                  // Información del artesano
                  if (_product.artisanName != null) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Artesano:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _product.artisanName!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_product.artisanPhone != null)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _product.artisanPhone!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchWhatsApp,
        icon: const Icon(Icons.chat),
        label: const Text('Contactar por WhatsApp'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ✅ NUEVO: Carrusel para múltiples imágenes
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

    return SizedBox(
      height: 300,
      child: PageView.builder(
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
    );
  }
}