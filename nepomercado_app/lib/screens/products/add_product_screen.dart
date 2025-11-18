import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_indicator.dart';

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
      // ✅ CORREGIDO: Cambiar 'image' por 'images'
      final response = await _apiService.createProduct(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        description: _descriptionController.text.trim(),
        images: _selectedImages, // ✅ CORREGIDO: 'images' en plural
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
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() => _selectedImages.clear());
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // ✅ MEJORA: Verificar si el usuario está logueado
    // Si no está logueado, mostrar diálogo de registro
    void _checkAuthAndSubmit() async {
      if (authService.currentUser == null) {
        _showAuthRequiredDialog();
        return;
      }
      await _submitProduct();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearForm,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Creando producto...')
          : Padding(
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
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
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

                      // ✅ MEJORA: Mostrar estado de autenticación
                      if (authService.currentUser == null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange[800]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Debes registrarte para publicar productos',
                                  style: TextStyle(
                                    color: Colors.orange[800],
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
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _checkAuthAndSubmit, // ✅ CAMBIADO
                          style: ElevatedButton.styleFrom(
                            backgroundColor: authService.currentUser == null 
                                ? Colors.grey 
                                : Theme.of(context).primaryColor,
                          ),
                          child: Text(
                              authService.currentUser == null
                                  ? 'Regístrate para Publicar'
                                  : 'Publicar Producto',
                              style: TextStyle(
                                fontSize: 16,
                                color: authService.currentUser == null
                                    ? Colors.black   // texto negro cuando está gris
                                    : Colors.white,  // texto blanco cuando está primario
                              ),
                            ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Diálogo para cuando se requiere autenticación
  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registro Requerido'),
        content: const Text('Para publicar productos necesitas crear una cuenta. ¿Te gustaría registrarte ahora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            child: const Text('Registrarse'),
          ),
        ],
      ),
    );
  }

  // Selector para múltiples imágenes
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
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
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        
        // Placeholder cuando no hay imágenes
        if (_selectedImages.isEmpty)
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 50, color: Colors.grey),
                SizedBox(height: 8),
                Text('Selecciona imágenes del producto'),
                SizedBox(height: 4),
                Text(
                  'Máximo 5 imágenes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),
        
        // Botones de acción
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}