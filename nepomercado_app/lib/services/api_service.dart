import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nepomercado_app/models/search_filters.dart';
import '../config/constants.dart';
import '../models/api_response.dart';
import '../models/product.dart';
import '../models/user.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = Constants.apiBaseUrl;
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // AUTH ENDPOINTS
  Future<ApiResponse<dynamic>> register(String name, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: await _getHeaders(),
        body: json.encode({
          'name': name,
          'phone': phone,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      return ApiResponse.fromJson(data);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: await _getHeaders(),
        body: json.encode({
          'phone': phone,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      return ApiResponse.fromJson(data);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // PRODUCT ENDPOINTS
  Future<ApiResponse<List<Product>>> getProducts({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products?page=$page&limit=$limit'),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);
      final apiResponse = ApiResponse.fromJson(data);

      if (apiResponse.success && apiResponse.data != null) {
        final products = (apiResponse.data['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
        return ApiResponse(
          success: true,
          message: apiResponse.message,
          data: products,
        );
      }

      return ApiResponse(
        success: false,
        message: apiResponse.message,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Product>> getProductById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/$id'),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);
      final apiResponse = ApiResponse.fromJson(data);

      if (apiResponse.success && apiResponse.data != null) {
        final product = Product.fromJson(apiResponse.data['product']);
        return ApiResponse(
          success: true,
          message: apiResponse.message,
          data: product,
        );
      }

      return ApiResponse(
        success: false,
        message: apiResponse.message,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Product>> createProduct({
  required String name,
  required double price,
  required String description,
  required List<File> images,
}) async {
  try {
    final token = await _storage.getToken();
    
    print('📦 Creando producto con ${images.length} Imagenes');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/products'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // Campos de texto
    request.fields['name'] = name;  
    request.fields['price'] = price.toString();
    request.fields['description'] = description;

    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      final mimeType = _getMimeType(image.path);

      request.files.add(await http.MultipartFile.fromPath(
        'images', // Nombre del campo como un array
        image.path,
        contentType: MediaType.parse(mimeType), // ✅ Especificar content-type
      ));
   
      print('   - Imagen ${i + 1}: ${image.path} (MIME: $mimeType)');
    }
    print('📤 Enviando request...');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('📥 Respuesta recibida:');
    print('   - Status: ${response.statusCode}');
    print('   - Body: ${response.body}');

    // Verificar si es una respuesta JSON válida
    if (response.body.startsWith('<!DOCTYPE html>')) {
      throw Exception('El servidor respondió con HTML de error. Verifica los logs del backend.');
    }

    final data = json.decode(response.body);
    final apiResponse = ApiResponse.fromJson(data);

    if (apiResponse.success && apiResponse.data != null) {
      final product = Product.fromJson(apiResponse.data['product']);
      return ApiResponse(
        success: true,
        message: apiResponse.message,
        data: product,
      );
    }

    return ApiResponse(
      success: false,
      message: apiResponse.message,
    );

  } catch (e) {
    print('💥 ERROR en createProduct: $e');
    return ApiResponse(
      success: false,
      message: 'Error al crear producto: $e',
    );
  }
}

  // ✅ NUEVO: Actualizar producto
Future<ApiResponse<Product>> updateProduct({
  required String productId,
  required String name,
  required double price,
  required String description,
  required List<File> images,
}) async {
  try {
    final token = await _storage.getToken();
    
    print('🔄 ACTUALIZANDO PRODUCTO: $productId');

    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$_baseUrl/products/$productId'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // Campos de texto
    request.fields['name'] = name;
    request.fields['price'] = price.toString();
    request.fields['description'] = description;

    // Agregar nuevas imágenes
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final mimeType = _getMimeType(image.path);
      
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        image.path,
        contentType: MediaType.parse(mimeType),
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    final data = json.decode(response.body);
    final apiResponse = ApiResponse.fromJson(data);

    if (apiResponse.success && apiResponse.data != null) {
      final product = Product.fromJson(apiResponse.data['product']);
      return ApiResponse(
        success: true,
        message: apiResponse.message,
        data: product,
      );
    }

    return ApiResponse(
      success: false,
      message: apiResponse.message,
    );

  } catch (e) {
    print('💥 ERROR en updateProduct: $e');
    return ApiResponse(
      success: false,
      message: 'Error al actualizar producto: $e',
    );
  }
}

// ✅ NUEVO: Eliminar producto
Future<ApiResponse<dynamic>> deleteProduct(String productId) async {
  try {
    final token = await _storage.getToken();
    
    final response = await http.delete(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);
    return ApiResponse.fromJson(data);

  } catch (e) {
    print('💥 ERROR en deleteProduct: $e');
    return ApiResponse(
      success: false,
      message: 'Error al eliminar producto: $e',
    );
  }
}

Future<ApiResponse<List<Product>>> getMyProducts() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/user/my-products'),
      headers: await _getHeaders(),
    );

    final data = json.decode(response.body);

    if (data['success'] == true && data['data'] != null) {
      final productsJson = data['data']['products'] as List? ?? [];
      
      final List<Product> products = [];
      
      for (final item in productsJson) {
        try {
          if (item is Map<String, dynamic>) {
            final product = Product.fromJson(item);
            products.add(product);
          }
        } catch (e) {
          print('⚠️ Error procesando producto: $e');
          // Continuar con los demás productos
        }
      }

      return ApiResponse(
        success: true,
        message: data['message']?.toString() ?? 'Productos obtenidos exitosamente', // ← SOLUCIÓN
        data: products,
      );
    }

    return ApiResponse(
      success: false,
      message: data['message']?.toString() ?? 'Error al obtener productos', // ← TAMBIÉN AQUÍ
    );
  } catch (e, stackTrace) {
    print('💥 ERROR en getMyProducts: $e');
    print('📋 StackTrace: $stackTrace');
    return ApiResponse(
      success: false,
      message: 'Error de conexión: $e',
    );
  }
}
  Future<ApiResponse<Map<String, dynamic>>> toggleLike(String productId) async {
    try {
      final token = await _storage.getToken();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/products/$productId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      return ApiResponse.fromJson(data);

    } catch (e) {
      print('💥 ERROR en toggleLike: $e');
      return ApiResponse(
        success: false,
        message: 'Error al dar like: $e',
      );
    }
  }

  // ✅ NUEVO: Búsqueda con filtros
  Future<ApiResponse<Map<String, dynamic>>> searchProducts(SearchFilters filters) async {
    try {
      // Construir URL con parámetros de consulta
      final uri = Uri.parse('$_baseUrl/products/search/all').replace(
        queryParameters: filters.toQueryParams(),
      );

      print('🔍 Buscando productos: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);
      final apiResponse = ApiResponse.fromJson(data);

      if (apiResponse.success && apiResponse.data != null) {
        // Convertir productos
        final products = (apiResponse.data['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList();

        return ApiResponse(
          success: true,
          message: apiResponse.message,
          data: {
            'products': products,
            'pagination': apiResponse.data['pagination'],
            'filters': apiResponse.data['filters'],
          },
        );
      }

      return ApiResponse(
        success: false,
        message: apiResponse.message,
      );

    } catch (e) {
      print('💥 ERROR en searchProducts: $e');
      return ApiResponse(
        success: false,
        message: 'Error en búsqueda: $e',
      );
    }
  }
  
  // ✅ NUEVO: Obtener productos likeados
  Future<ApiResponse<List<Product>>> getLikedProducts() async {
    try {
      final token = await _storage.getToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/products/user/liked'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      final apiResponse = ApiResponse.fromJson(data);

      if (apiResponse.success && apiResponse.data != null) {
        final products = (apiResponse.data['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
        return ApiResponse(
          success: true,
          message: apiResponse.message,
          data: products,
        );
      }

      return ApiResponse(
        success: false,
        message: apiResponse.message,
      );

    } catch (e) {
      print('💥 ERROR en getLikedProducts: $e');
      return ApiResponse(
        success: false,
        message: 'Error obteniendo productos likeados: $e',
      );
    }
  }

  // ✅ NUEVO: Recuperación de contraseña
  Future<ApiResponse<dynamic>> forgotPassword(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone}),
      );

      final data = json.decode(response.body);
      return ApiResponse.fromJson(data);

    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error solicitando recuperación: $e',
      );
    }
  }

  // ✅ NUEVO: Verificar código
  Future<ApiResponse<dynamic>> verifyRecoveryCode(String phone, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'code': code}),
      );

      final data = json.decode(response.body);
      return ApiResponse.fromJson(data);

    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error verificando código: $e',
      );
    }
  }

  // ✅ NUEVO: Resetear contraseña
  Future<ApiResponse<dynamic>> resetPassword(String tempToken, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tempToken': tempToken,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);
      return ApiResponse.fromJson(data);

    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error reseteando contraseña: $e',
      );
    }
  }

  // Helper para detectar MIME type
  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp'
    };
    return mimeTypes[extension] ?? 'image/jpeg';
  }
}