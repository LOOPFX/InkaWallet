import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/accessibility_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final AccessibilityService _accessibility = AccessibilityService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _error;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  
  Future<void> checkAuth() async {
    await _api.loadToken();
    try {
      _user = await _api.getUserProfile();
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
    }
  }
  
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    bool accessibilityEnabled = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        accessibilityEnabled: accessibilityEnabled,
      );
      
      _user = response['user'];
      _isAuthenticated = true;
      
      await _accessibility.announceAndVibrate(
        'Welcome to InkaWallet, ${_user!['full_name']}!',
        important: true,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      await _accessibility.speak('Registration failed. $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.login(email: email, password: password);
      _user = response['user'];
      _isAuthenticated = true;
      
      await _accessibility.announceAndVibrate(
        'Welcome back, ${_user!['full_name']}!',
        important: true,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      await _accessibility.speak('Login failed. $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await _api.clearToken();
    _isAuthenticated = false;
    _user = null;
    await _accessibility.speak('You have been logged out');
    notifyListeners();
  }
}
