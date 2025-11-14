import 'package:flutter/material.dart';
import './api_service.dart';
import './storage_service.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final userData = await _storageService.getUser();
    if (userData != null) {
      _currentUser = User.fromJson(userData);
      notifyListeners();
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(phone, password);
      
      if (response.success && response.data != null) {
        // Guardar token y datos de usuario
        await _storageService.saveToken(response.data['token']);
        await _storageService.saveUser(response.data['user']);
        
        _currentUser = User.fromJson(response.data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(name, phone, password);
      
      if (response.success && response.data != null) {
        // Guardar token y datos de usuario
        await _storageService.saveToken(response.data['token']);
        await _storageService.saveUser(response.data['user']);
        
        _currentUser = User.fromJson(response.data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.clearStorage();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null && _currentUser != null;
  }
}