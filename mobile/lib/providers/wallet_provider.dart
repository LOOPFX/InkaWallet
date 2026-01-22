import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';

enum WalletStatus {
  initial,
  loading,
  loaded,
  error,
}

/// WalletProvider manages wallet state and balance
class WalletProvider with ChangeNotifier {
  final _apiService = ApiService();
  
  WalletStatus _status = WalletStatus.initial;
  Wallet? _wallet;
  String? _error;

  WalletStatus get status => _status;
  Wallet? get wallet => _wallet;
  bool get isLoading => _status == WalletStatus.loading;
  double get balance => _wallet?.balance ?? 0.0;
  String? get error => _error;

  /// Update auth token
  void updateAuthToken(String? token) {
    if (token != null) {
      loadWallet();
    }
  }

  /// Load wallet balance
  Future<void> loadWallet() async {
    _status = WalletStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _wallet = await _apiService.getWalletBalance();
      _status = WalletStatus.loaded;
    } catch (e) {
      _status = WalletStatus.error;
      _error = e.toString();
    }

    notifyListeners();
  }

  /// Refresh wallet
  Future<void> refresh() async {
    await loadWallet();
  }

  /// Update balance locally (after transaction)
  void updateBalance(double newBalance) {
    if (_wallet != null) {
      _wallet = _wallet!.copyWith(balance: newBalance);
      notifyListeners();
    }
  }

  /// Clear wallet data
  void clear() {
    _wallet = null;
    _status = WalletStatus.initial;
    _error = null;
    notifyListeners();
  }
}
