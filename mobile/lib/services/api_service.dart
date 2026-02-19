import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }
  
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
  
  // Auth APIs
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    bool accessibilityEnabled = true,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'accessibility_enabled': accessibilityEnabled,
      }),
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Registration failed');
    }
  }
  
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
    }
  }
  
  Future<Map<String, dynamic>> googleAuth({
    required String googleId,
    required String email,
    required String fullName,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'google_id': googleId,
        'email': email,
        'full_name': fullName,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      throw Exception('Google authentication failed');
    }
  }
  
  // Wallet APIs
  Future<Map<String, dynamic>> getBalance() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/wallet/balance'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch balance');
    }
  }
  
  // Transaction APIs
  Future<Map<String, dynamic>> sendMoney({
    required String receiverPhone,
    required double amount,
    String? description,
    String paymentMethod = 'inkawallet',
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/transactions/send'),
      headers: _headers,
      body: jsonEncode({
        'receiver_phone': receiverPhone,
        'amount': amount,
        'description': description,
        'payment_method': paymentMethod,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Transfer failed');
    }
  }
  
  Future<Map<String, dynamic>> receiveMoney({
    required double amount,
    required String paymentMethod,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/transactions/receive'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'payment_method': paymentMethod,
        'description': description,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Receive failed');
    }
  }
  
  Future<List<dynamic>> getTransactionHistory() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/transactions/history'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch history');
    }
  }
  
  // User APIs
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }
  
  Future<void> updateAccessibilitySettings({
    required bool accessibilityEnabled,
    required bool voiceEnabled,
    required bool hapticsEnabled,
    required bool biometricEnabled,
  }) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/users/accessibility'),
      headers: _headers,
      body: jsonEncode({
        'accessibility_enabled': accessibilityEnabled,
        'voice_enabled': voiceEnabled,
        'haptics_enabled': hapticsEnabled,
        'biometric_enabled': biometricEnabled,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update settings');
    }
  }
}
