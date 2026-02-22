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

  // Money Request APIs
  Future<Map<String, dynamic>> createMoneyRequest({
    required String payerIdentifier,
    required double amount,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/money-requests/create'),
      headers: _headers,
      body: jsonEncode({
        'payer_identifier': payerIdentifier,
        'amount': amount,
        'description': description,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to create request');
    }
  }

  Future<List<dynamic>> getSentRequests() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/money-requests/sent'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch sent requests');
    }
  }

  Future<List<dynamic>> getReceivedRequests() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/money-requests/received'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch received requests');
    }
  }

  Future<Map<String, dynamic>> payMoneyRequest({
    required String paymentToken,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/money-requests/pay/$paymentToken'),
      headers: _headers,
      body: jsonEncode({
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Payment failed');
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/money-requests/notifications'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch notifications');
    }
  }
  // Services APIs
  Future<Map<String, dynamic>> buyAirtime({
    required String phoneNumber,
    required String provider,
    required double amount,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/services/airtime'),
      headers: _headers,
      body: jsonEncode({
        'phone_number': phoneNumber,
        'provider': provider,
        'amount': amount,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Airtime purchase failed');
    }
  }

  Future<List<String>> getBillProviders(String billType) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/services/providers/$billType'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['providers']);
    } else {
      throw Exception('Failed to fetch providers');
    }
  }

  Future<Map<String, dynamic>> payBill({
    required String billType,
    required String provider,
    required String accountNumber,
    required double amount,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/services/bill'),
      headers: _headers,
      body: jsonEncode({
        'bill_type': billType,
        'provider': provider,
        'account_number': accountNumber,
        'amount': amount,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Bill payment failed');
    }
  }

  Future<Map<String, dynamic>> topUpWallet({
    required String source,
    required double amount,
    required String sourceReference,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/services/topup'),
      headers: _headers,
      body: jsonEncode({
        'source': source,
        'amount': amount,
        'source_reference': sourceReference,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Top-up failed');
    }
  }

  Future<List<dynamic>> getServiceHistory(String type) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/services/history/$type'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch history');
    }
  }

  // QR APIs
  Future<String> getMyQRData() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/qr/me'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['qr_data'];
    } else {
      throw Exception('Failed to generate QR');
    }
  }

  Future<Map<String, dynamic>> validateQRCode(String qrData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/qr/validate'),
      headers: _headers,
      body: jsonEncode({
        'qr_data': qrData,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Invalid QR code');
    }
  }

  // Credit Score APIs
  Future<Map<String, dynamic>> getCreditScore() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/credit/score'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch credit score');
    }
  }

  Future<Map<String, dynamic>> recalculateCreditScore() async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/credit/recalculate'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to recalculate credit score');
    }
  }

  Future<Map<String, dynamic>> getCreditHistory() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/credit/history'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch credit history');
    }
  }

  // BNPL APIs
  Future<Map<String, dynamic>> getBNPLLoans() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/bnpl/loans'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch loans');
    }
  }

  Future<Map<String, dynamic>> applyForBNPL({
    required String merchantName,
    required String itemDescription,
    required double amount,
    required int installments,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/bnpl/apply'),
      headers: _headers,
      body: jsonEncode({
        'merchant_name': merchantName,
        'item_description': itemDescription,
        'amount': amount,
        'installments': installments,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'BNPL application failed');
    }
  }

  Future<Map<String, dynamic>> payBNPL({
    required String loanId,
    required String password,
    String? paymentMethod,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/bnpl/pay'),
      headers: _headers,
      body: jsonEncode({
        'loan_id': loanId,
        'password': password,
        'payment_method': paymentMethod ?? 'inkawallet',
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Payment failed');
    }
  }
}