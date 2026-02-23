import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/accessibility_service.dart';
import '../services/notification_service.dart';

class WalletProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final AccessibilityService _accessibility = AccessibilityService();
  final NotificationService _notifications = NotificationService();
  
  double _balance = 0.0;
  String _currency = 'MKW';
  bool _isLocked = false;
  bool _isLoading = false;
  List<dynamic> _transactions = [];
  String? _error;
  
  double get balance => _balance;
  String get currency => _currency;
  bool get isLocked => _isLocked;
  bool get isLoading => _isLoading;
  List<dynamic> get transactions => _transactions;
  String? get error => _error;
  
  String get formattedBalance => '$currency ${_balance.toStringAsFixed(2)}';
  
  Future<void> fetchBalance() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final data = await _api.getBalance();
      _balance = double.parse(data['balance'].toString());
      _currency = data['currency'] ?? 'MKW';
      _isLocked = data['is_locked'] == 1;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchTransactions() async {
    try {
      _transactions = await _api.getTransactionHistory();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<bool> sendMoney({
    required String receiverPhone,
    required double amount,
    String? description,
    String paymentMethod = 'inkawallet',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _accessibility.speak('Processing transfer');
      
      final response = await _api.sendMoney(
        receiverPhone: receiverPhone,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
      );
      
      await fetchBalance();
      await fetchTransactions();
      
      // Add notification
      await _notifications.addNotification(
        title: 'Money Sent',
        message: 'Successfully sent $currency ${amount.toStringAsFixed(2)} to $receiverPhone',
        type: 'transaction',
        data: {
          'type': 'send',
          'amount': amount,
          'recipient': receiverPhone,
        },
      );
      
      await _accessibility.announceAndVibrate(
        'Successfully sent $currency ${amount.toStringAsFixed(2)} to $receiverPhone',
        important: true,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      await _accessibility.speak('Transfer failed. $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> receiveMoney({
    required double amount,
    required String paymentMethod,
    String? description,
  }) async {
    try {
      await _api.receiveMoney(
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
      );
      
      await fetchBalance();
      await fetchTransactions();
      
      // Add notification
      await _notifications.addNotification(
        title: 'Money Received',
        message: 'Received $currency ${amount.toStringAsFixed(2)} from $paymentMethod',
        type: 'transaction',
        data: {
          'type': 'receive',
          'amount': amount,
          'source': paymentMethod,
        },
      );
      
      await _accessibility.announceAndVibrate(
        'Received $currency ${amount.toStringAsFixed(2)} from $paymentMethod',
        important: true,
      );
      
      return true;
    } catch (e) {
      await _accessibility.speak('Failed to receive money');
      return false;
    }
  }
}
