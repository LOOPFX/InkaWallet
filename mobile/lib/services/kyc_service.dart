import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class KycService {
  static const String baseUrl = 'http://localhost:3000/api/kyc';

  // Check if transaction is allowed based on KYC limits
  Future<Map<String, dynamic>> checkTransactionLimits(double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/check-limits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount}),
      );

      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      print('Error checking KYC limits: $e');
      return {
        'success': false,
        'data': {'message': 'Unable to verify transaction limits'},
      };
    }
  }

  // Get KYC status
  Future<Map<String, dynamic>?> getKycStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching KYC status: $e');
      return null;
    }
  }

  // Check if KYC is verified
  Future<bool> isKycVerified() async {
    final status = await getKycStatus();
    return status != null && status['kyc_status'] == 'verified';
  }

  // Get verification level
  Future<String?> getVerificationLevel() async {
    final status = await getKycStatus();
    return status?['verification_level'];
  }

  // Get transaction limits
  Future<Map<String, double>?> getTransactionLimits() async {
    final status = await getKycStatus();
    if (status == null) return null;

    return {
      'daily': status['daily_transaction_limit']?.toDouble() ?? 0.0,
      'monthly': status['monthly_transaction_limit']?.toDouble() ?? 0.0,
    };
  }
}
