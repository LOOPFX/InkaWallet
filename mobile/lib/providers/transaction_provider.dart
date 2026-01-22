import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/transaction.dart' as models;
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

enum TransactionStatus {
  initial,
  loading,
  loaded,
  sending,
  sent,
  error,
}

/// TransactionProvider manages transaction operations and history
class TransactionProvider with ChangeNotifier {
  final _apiService = ApiService();
  final _connectivity = Connectivity();
  
  TransactionStatus _status = TransactionStatus.initial;
  List<models.Transaction> _transactions = [];
  models.Transaction? _currentTransaction;
  String? _error;
  bool _isOnline = true;

  TransactionStatus get status => _status;
  List<models.Transaction> get transactions => _transactions;
  bool get isLoading => _status == TransactionStatus.loading;
  models.Transaction? get currentTransaction => _currentTransaction;
  String? get error => _error;
  bool get isOnline => _isOnline;

  TransactionProvider() {
    _initConnectivity();
  }

  /// Initialize connectivity monitoring
  void _initConnectivity() {
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
      
      if (_isOnline) {
        _syncOfflineTransactions();
      }
    });
  }

  /// Update auth token
  void updateAuthToken(String? token) {
    if (token != null) {
      loadTransactions();
    }
  }

  /// Load transaction history
  Future<void> loadTransactions({int page = 1}) async {
    _status = TransactionStatus.loading;
    _error = null;
    notifyListeners();

    try {
      if (_isOnline) {
        // Load from server
        _transactions = await _apiService.getTransactionHistory(page: page);
        
        // Cache locally
        for (var transaction in _transactions) {
          await StorageService.saveTransaction(transaction);
        }
      } else {
        // Load from local storage
        _transactions = await StorageService.getAllTransactions();
      }
      
      _status = TransactionStatus.loaded;
    } catch (e) {
      _status = TransactionStatus.error;
      _error = e.toString();
      
      // Fallback to local storage
      _transactions = await StorageService.getAllTransactions();
    }

    notifyListeners();
  }

  /// Send money
  Future<bool> sendMoney({
    required String recipientPhone,
    required double amount,
    required String walletProvider,
    String? description,
  }) async {
    _status = TransactionStatus.sending;
    _error = null;
    notifyListeners();

    try {
      if (_isOnline) {
        // Send online
        _currentTransaction = await _apiService.sendMoney(
          recipientPhone: recipientPhone,
          amount: amount,
          walletProvider: walletProvider,
          description: description,
        );
        
        // Save locally
        await StorageService.saveTransaction(_currentTransaction!);
      } else {
        // Queue offline
        _currentTransaction = _createOfflineTransaction(
          recipientPhone: recipientPhone,
          amount: amount,
          walletProvider: walletProvider,
          description: description,
        );
        
        await StorageService.saveTransaction(_currentTransaction!);
      }
      
      // Add to local list
      _transactions.insert(0, _currentTransaction!);
      _status = TransactionStatus.sent;
      notifyListeners();
      return true;
    } catch (e) {
      _status = TransactionStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Create offline transaction
  models.Transaction _createOfflineTransaction({
    required String recipientPhone,
    required double amount,
    required String walletProvider,
    String? description,
  }) {
    return models.Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      walletId: '', // Will be filled when synced
      type: models.TransactionType.send,
      amount: amount,
      currency: AppConstants.currencySymbol,
      recipientPhone: recipientPhone,
      recipientWalletProvider: walletProvider,
      description: description,
      status: models.TransactionStatus.pending,
      createdAt: DateTime.now(),
      isSynced: false,
    );
  }

  /// Sync offline transactions
  Future<void> _syncOfflineTransactions() async {
    final unsyncedTransactions = await StorageService.getUnsyncedTransactions();
    
    for (var transaction in unsyncedTransactions) {
      try {
        await _apiService.sendMoney(
          recipientPhone: transaction.recipientPhone!,
          amount: transaction.amount,
          walletProvider: transaction.recipientWalletProvider!,
          description: transaction.description,
        );
        
        await StorageService.markTransactionSynced(transaction.id);
      } catch (e) {
        print('Failed to sync transaction ${transaction.id}: $e');
      }
    }
    
    // Reload transactions after sync
    await loadTransactions();
  }

  /// Get transaction details
  Future<void> loadTransactionDetails(String transactionId) async {
    try {
      _currentTransaction = await _apiService.getTransactionDetails(transactionId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh transactions
  Future<void> refresh() async {
    await loadTransactions();
  }

  /// Clear transactions
  void clear() {
    _transactions = [];
    _currentTransaction = null;
    _status = TransactionStatus.initial;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
