import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// AuthProvider manages authentication state
class AuthProvider with ChangeNotifier {
  final _apiService = ApiService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Initialize auth state
  Future<void> initialize() async {
    await _apiService.initialize();
    
    final savedToken = StorageService.getString(AppConstants.keyAuthToken);
    if (savedToken != null) {
      _token = savedToken;
      _status = AuthStatus.authenticated;
      await _loadUserProfile();
    } else {
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  /// Register new user
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );

      _token = response['token'];
      _user = User.fromJson(response['user']);
      _status = AuthStatus.authenticated;
      
      await StorageService.saveString(AppConstants.keyAuthToken, _token!);
      await StorageService.saveString(AppConstants.keyUserId, _user!.id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );

      _token = response['token'];
      _user = User.fromJson(response['user']);
      _status = AuthStatus.authenticated;
      
      await StorageService.saveString(AppConstants.keyAuthToken, _token!);
      await StorageService.saveString(AppConstants.keyUserId, _user!.id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } finally {
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      
      await StorageService.clearAll();
      notifyListeners();
    }
  }

  /// Load user profile
  Future<void> _loadUserProfile() async {
    try {
      _user = await _apiService.getUserProfile();
      notifyListeners();
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      _user = await _apiService.updateUserProfile(data);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
