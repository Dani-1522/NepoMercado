import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:NepoMercado/config/categories.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/product.dart';
import '../../widgets/loading_indicator.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;
  bool _isDeleting = false;
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'otros';

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.product.name;
    _priceController.text = widget.product.price.toString();
    _descriptionController.text = widget.product.description;
    _existingImageUrls = List.from(widget.product.imageUrls);
    _selectedCategory = widget.product.category ?? 'otros';
  }

  String _getCategoryDisplayName(String category) {
    final names = {
      'todos': 'Todos',
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

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (images != null) {
        setState(() {
          _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.sublist(0, 5);
            _showInfoSnackbar('Máximo 5 imágenes permitidas');
          }
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al seleccionar imágenes: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null && _selectedImages.length < 5) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      } else if (_selectedImages.length >= 5) {
        _showInfoSnackbar('Máximo 5 imágenes permitidas');
      }
    } catch (e) {
      _showErrorSnackbar('Error al tomar foto: $e');
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImageUrls.isEmpty && _selectedImages.isEmpty) {
      _showErrorSnackbar('El producto debe tener al menos una imagen');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.updateProduct(
        productId: widget.product.id,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        images: _selectedImages,
      );

      setState(() => _isLoading = false);

      if (response.success) {
        _showSuccessSnackbar('Producto actualizado exitosamente');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackbar(response.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error al actualizar producto: $e');
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Producto',
          style: TextStyle(color: Color(0xFF0F4C5C)),
        ),
        content: const Text('¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: Color(0xFFE9965C)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final response = await _apiService.deleteProduct(widget.product.id);

      setState(() => _isDeleting = false);

      if (response.success) {
        _showSuccessSnackbar('Producto eliminado exitosamente');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackbar(response.message);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      _showErrorSnackbar('Error al eliminar producto: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE9965C), 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF3A9188), 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0F4C5C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Producto',
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
          if (!_isDeleting)
            TextButton(
              onPressed: _deleteProduct,
              child: Text(
                'Eliminar',
                style: TextStyle(color: Color(0xFFE9965C)), 
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EDE4), 
      body: SafeArea(
        bottom: true,
        child: (_isLoading || _isDeleting)
            ? LoadingIndicator(
                message: _isDeleting ? 'Eliminando producto...' : 'Actualizando producto...')
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Imágenes existentes
                        if (_existingImageUrls.isNotEmpty) ...[
                          _buildImageSection(
                            'Imágenes Actuales',
                            _existingImageUrls,
                            _removeExistingImage,
                            isNetworkImage: true,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Nuevas imágenes
                        _buildImageSection(
                          'Nuevas Imágenes (${_selectedImages.length}/5)',
                          _selectedImages.map((f) => f.path).toList(),
                          _removeNewImage,
                          isNetworkImage: false,
                        ),

                        const SizedBox(height: 24),
                        _buildFormFields(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImageSection(String title, List<String> imagePaths, Function(int) onRemove, {bool isNetworkImage = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F4C5C),
          ),
        ),
        const SizedBox(height: 12),
        if (imagePaths.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF3A9188)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isNetworkImage
                          ? Image.network(
                              imagePaths[index],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFF4EDE4),
                                  child: const Icon(Icons.error, color: Color(0xFF3A9188)),
                                );
                              },
                            )
                          : Image.file(
                              File(imagePaths[index]),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE9965C), 
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        else
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF3A9188).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 40, color: Color(0xFF3A9188)),
                const SizedBox(height: 8),
                Text(
                  'No hay imágenes',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        
        if (!isNetworkImage) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.photo_library, color: Color(0xFF0F4C5C)),
                  label: Text(
                    'Galería',
                    style: TextStyle(color: Color(0xFF0F4C5C)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF0F4C5C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: Icon(Icons.camera_alt, color: Color(0xFF0F4C5C)),
                  label: Text(
                    'Cámara',
                    style: TextStyle(color: Color(0xFF0F4C5C)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF0F4C5C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nombre del producto',
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Selector de categoría
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Categoría',
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
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
          items: ProductCategories.allCategories
              .where((cat) => cat != 'todos')
              .map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Text(
                    ProductCategories.getIcon(category),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getCategoryDisplayName(category),
                    style: const TextStyle(
                      color: Color(0xFF202124),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value ?? 'otros';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona una categoría';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: 'Precio',
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
            prefixText: '\$ ',
            prefixStyle: const TextStyle(
              color: Color(0xFF0F4C5C),
              fontWeight: FontWeight.w600,
            ),
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
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el precio';
            }
            final price = double.tryParse(value);
            if (price == null || price <= 0) {
              return 'Por favor ingresa un precio válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Descripción',
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
            alignLabelWithHint: true,
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
          maxLines: 4,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa la descripción';
            }
            if (value.length < 10) {
              return 'La descripción debe tener al menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _updateProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A9188),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Actualizar Producto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Color(0xFF0F4C5C)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF0F4C5C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}