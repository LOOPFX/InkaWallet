import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import 'encryption_service.dart';

/// ApiService handles all HTTP requests to the backend
/// Implements security measures including encryption and token refresh
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  final _encryptionService = EncryptionService();
  
  String? _authToken;
  String? _refreshToken;

  /// Initialize with saved tokens
  Future<void> initialize() async {
    _authToken = await _storage.read(key: AppConstants.keyAuthToken);
    _refreshToken = await _storage.read(key: AppConstants.keyRefreshToken);
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  /// Set refresh token
  void setRefreshToken(String token) {
    _refreshToken = token;
    _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  /// Clear tokens (logout)
  Future<void> clearTokens() async {
    _authToken = null;
    _refreshToken = null;
    await _storage.delete(key: AppConstants.keyAuthToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
  }

  /// Get common headers
  Map<String, String> _getHeaders({bool requiresAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Refresh authentication token
  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.refreshTokenEndpoint}'),
        headers: _getHeaders(),
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setAuthToken(data['token']);
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }

    return false;
  }

  /// Handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Bad request');
    } else if (response.statusCode == 500) {
      throw Exception('Server error');
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }

  /// Make authenticated GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: true),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Make authenticated POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool requiresAuth = true}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Make authenticated PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: true),
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Make authenticated DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: true),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Authentication APIs

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final encryptedPassword = _encryptionService.hashPassword(password);
    
    final response = await post(
      AppConstants.registerEndpoint,
      {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': encryptedPassword,
      },
      requiresAuth: false,
    );

    setAuthToken(response['token']);
    setRefreshToken(response['refreshToken']);

    return response;
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final encryptedPassword = _encryptionService.hashPassword(password);
    
    final response = await post(
      AppConstants.loginEndpoint,
      {
        'emailOrPhone': emailOrPhone,
        'password': encryptedPassword,
      },
      requiresAuth: false,
    );

    setAuthToken(response['token']);
    setRefreshToken(response['refreshToken']);

    return response;
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await post(AppConstants.logoutEndpoint, {});
    } finally {
      await clearTokens();
    }
  }

  // Wallet APIs

  /// Get wallet balance
  Future<Wallet> getWalletBalance() async {
    final response = await get(AppConstants.balanceEndpoint);
    return Wallet.fromJson(response['wallet']);
  }

  // Transaction APIs

  /// Send money
  Future<Transaction> sendMoney({
    required String recipientPhone,
    required double amount,
    required String walletProvider,
    String? description,
  }) async {
    final response = await post(
      AppConstants.sendMoneyEndpoint,
      {
        'recipient_phone': recipientPhone,
        'amount': amount,
        'wallet_provider': walletProvider,
        'description': description,
      },
    );

    return Transaction.fromJson(response['transaction']);
  }

  /// Get transaction history
  Future<List<Transaction>> getTransactionHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await get(
      '${AppConstants.transactionHistoryEndpoint}?page=$page&limit=$limit',
    );

    final transactions = (response['transactions'] as List)
        .map((json) => Transaction.fromJson(json))
        .toList();

    return transactions;
  }

  /// Get transaction details
  Future<Transaction> getTransactionDetails(String transactionId) async {
    final response = await get(
      '${AppConstants.transactionDetailsEndpoint}/$transactionId',
    );

    return Transaction.fromJson(response['transaction']);
  }

  // User APIs

  /// Get user profile
  Future<User> getUserProfile() async {
    final response = await get(AppConstants.profileEndpoint);
    return User.fromJson(response['user']);
  }

  /// Update user profile
  Future<User> updateUserProfile(Map<String, dynamic> data) async {
    final response = await put(AppConstants.updateProfileEndpoint, data);
    return User.fromJson(response['user']);
  }

  // Feedback API

  /// Submit user feedback
  Future<void> submitFeedback({
    required String subject,
    required String message,
    required int rating,
  }) async {
    await post(
      AppConstants.feedbackEndpoint,
      {
        'subject': subject,
        'message': message,
        'rating': rating,
      },
    );
  }
}
