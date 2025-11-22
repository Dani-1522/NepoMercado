
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/constants.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

class UserService {
  final StorageService _storageService = StorageService();
  
  // Usa la misma URL base de Constants
  final String _baseUrl = Constants.apiBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Obtener perfil del usuario actual
  Future<ApiResponse<User>> getMyProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/profile/me'),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        final user = User.fromJson(data['data']['user']);
        return ApiResponse(
          success: true,
          message: data['message']?.toString() ?? 'Perfil obtenido',
          data: user,
        );
      }

      return ApiResponse(
        success: false,
        message: data['message']?.toString() ?? 'Error al obtener perfil',
      );
    } catch (e) {
      print('ERROR en getMyProfile: $e');
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // Obtener perfil de otro usuario por ID
Future<ApiResponse<User>> getUserProfile(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: await _getHeaders(),
    );

    final data = json.decode(response.body);
    
    if (data['success'] == true) {
      final user = User.fromJson(data['data']['user']);
      return ApiResponse(
        success: true,
        message: data['message']?.toString() ?? 'Perfil obtenido',
        data: user,
      );
    }

    return ApiResponse(
      success: false,
      message: data['message']?.toString() ?? 'Error al obtener perfil',
    );
  } catch (e) {
    print('ERROR en getUserProfile: $e');
    return ApiResponse(
      success: false,
      message: 'Error de conexión: $e',
    );
  }
}
  // Actualizar información básica
  Future<ApiResponse<User>> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile/update'),
        headers: await _getHeaders(),
        body: json.encode({
          'name': name,
          'phone': phone,
        }),
      );

      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        final user = User.fromJson(data['data']['user']);
        return ApiResponse(
          success: true,
          message: data['message']?.toString() ?? 'Perfil actualizado',
          data: user,
        );
      }

      return ApiResponse(
        success: false,
        message: data['message']?.toString() ?? 'Error al actualizar perfil',
      );
    } catch (e) {
      print('ERROR en updateProfile: $e');
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // Buscar vendedores por nombre o ID
  Future<ApiResponse<List<User>>> searchVendors(String query) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/search/vendors?query=$query'),
      headers: await _getHeaders(),
    );

    final data = json.decode(response.body);
    
    if (data['success'] == true) {
      final vendors = (data['data']['users'] as List)
          .map((item) => User.fromJson(item))
          .toList();
      return ApiResponse(
        success: true,
        message: data['message']?.toString() ?? 'Vendedores encontrados',
        data: vendors,
      );
    }

    return ApiResponse(
      success: false,
      message: data['message']?.toString() ?? 'Error buscando vendedores',
    );
  } catch (e) {
    print('ERROR en searchVendors: $e');
    return ApiResponse(
      success: false,
      message: 'Error de conexión: $e',
    );
  }
}
  // Cambiar contraseña
  Future<ApiResponse<dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile/change-password'),
        headers: await _getHeaders(),
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);
      
      return ApiResponse(
        success: data['success'] == true,
        message: data['message']?.toString() ?? 
          (data['success'] == true ? 'Contraseña actualizada' : 'Error al cambiar contraseña'),
      );
    } catch (e) {
      print('ERROR en changePassword: $e');
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // Subir foto de perfil
  Future<ApiResponse<User>> uploadProfileImage(XFile imageFile) async {
    try {
      final token = await _storageService.getToken();
      
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/users/profile/upload-image'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Agregar archivo
      final file = await http.MultipartFile.fromPath(
        'profileImage',
        imageFile.path,
      );
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        final user = User.fromJson(data['data']['user']);
        return ApiResponse(
          success: true,
          message: data['message']?.toString() ?? 'Foto actualizada',
          data: user,
        );
      }

      return ApiResponse(
        success: false,
        message: data['message']?.toString() ?? 'Error al subir imagen',
      );
    } catch (e) {
      
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // Eliminar foto de perfil
  Future<ApiResponse<User>> deleteProfileImage() async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/profile/delete-image'),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        final user = User.fromJson(data['data']['user']);
        return ApiResponse(
          success: true,
          message: data['message']?.toString() ?? 'Foto eliminada',
          data: user,
        );
      }

      return ApiResponse(
        success: false,
        message: data['message']?.toString() ?? 'Error al eliminar imagen',
      );
    } catch (e) {
     
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
}