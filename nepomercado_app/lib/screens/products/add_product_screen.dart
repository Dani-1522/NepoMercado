import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../config/categories.dart'; 

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<File> _selectedImages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'otros'; 

  //Método para obtener nombre display de categoría
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
          // Limitar a 5 imágenes máximo
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

      if (image != null) {
        setState(() {
          if (_selectedImages.length < 5) {
            _selectedImages.add(File(image.path));
          } else {
            _showInfoSnackbar('Máximo 5 imágenes permitidas');
          }
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al tomar foto: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showErrorSnackbar('Por favor selecciona al menos una imagen');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.createProduct(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        description: _descriptionController.text.trim(),
        category: _selectedCategory, 
        images: _selectedImages,
      );

      setState(() => _isLoading = false);

      if (response.success) {
        _showSuccessSnackbar('Producto creado exitosamente');
        Navigator.pop(context);
      } else {
        _showErrorSnackbar(response.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error al crear producto: $e');
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

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedImages.clear();
      _selectedCategory = 'otros'; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    void _checkAuthAndSubmit() async {
      if (authService.currentUser == null) {
        _showAuthRequiredDialog();
        return;
      }
      await _submitProduct();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agregar Producto',
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
            icon: const Icon(Icons.clear, color: Color(0xFF0F4C5C)),
            onPressed: _clearForm,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EDE4), 
      body: _isLoading
          ? const LoadingIndicator(message: 'Creando producto...')
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Selector de múltiples imágenes
                        _buildImageSelector(),
                        const SizedBox(height: 24),

                        // Campos del formulario
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

                        //Selector de categoría
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
                        const SizedBox(height: 24),

                        // Estado de autenticación
                        if (authService.currentUser == null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9965C).withOpacity(0.1),
                              border: Border.all(color: const Color(0xFFE9965C)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: const Color(0xFFE9965C)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Debes registrarte para publicar productos',
                                    style: TextStyle(
                                      color: const Color(0xFF0F4C5C),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Botón de enviar
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _checkAuthAndSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: authService.currentUser == null 
                                  ? const Color(0xFF64748B) 
                                  : const Color(0xFF3A9188), 
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              authService.currentUser == null
                                  ? 'Regístrate para Publicar'
                                  : 'Publicar Producto',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Registro Requerido',
          style: TextStyle(color: Color(0xFF0F4C5C)),
        ),
        content: const Text('Para publicar productos necesitas crear una cuenta. ¿Te gustaría registrarte ahora?'),
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
              style: TextStyle(
                color: Color(0xFF0F4C5C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    return Column(
      children: [
        // Contador de imágenes
        Row(
          children: [
            Text(
              'Imágenes (${_selectedImages.length}/5)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F4C5C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Grid de imágenes seleccionadas
        if (_selectedImages.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
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
                      child: Image.file(
                        _selectedImages[index],
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
                      onTap: () => _removeImage(index),
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
          ),
          const SizedBox(height: 16),
        ],
        
        // Placeholder cuando no hay imágenes
        if (_selectedImages.isEmpty)
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF3A9188).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 50, color: Color(0xFF3A9188)),
                const SizedBox(height: 8),
                Text(
                  'Selecciona imágenes del producto',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Máximo 5 imágenes',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),
        
        // Botones de acción
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