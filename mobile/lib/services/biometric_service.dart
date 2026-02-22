import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  
  bool _isEnabled = false;
  List<BiometricType> _availableTypes = [];
  
  bool get isEnabled => _isEnabled;
  List<BiometricType> get availableTypes => _availableTypes;
  
  /// Initialize biometric service and check availability
  Future<void> initialize() async {
    await _loadSettings();
    await checkAvailability();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('biometric_enabled') ?? false;
  }
  
  /// Check if device supports biometric authentication
  Future<bool> checkAvailability() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      
      if (canCheckBiometrics && isDeviceSupported) {
        _availableTypes = await _auth.getAvailableBiometrics();
        return _availableTypes.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }
  
  /// Authenticate user with biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    if (!_isEnabled) {
      return false;
    }
    
    try {
      final isAvailable = await checkAvailability();
      if (!isAvailable) {
        return false;
      }
      
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.message}');
      return false;
    }
  }
  
  /// Authenticate for login
  Future<bool> authenticateForLogin() async {
    return await authenticate(
      reason: 'Authenticate to log in to InkaWallet',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }
  
  /// Authenticate for transactions
  Future<bool> authenticateForTransaction(double amount) async {
    return await authenticate(
      reason: 'Authenticate to confirm transaction of MKW ${amount.toStringAsFixed(2)}',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }
  
  /// Authenticate for settings
  Future<bool> authenticateForSettings() async {
    return await authenticate(
      reason: 'Authenticate to change security settings',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }
  
  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    final authenticated = await authenticate(
      reason: 'Authenticate to enable biometric login',
    );
    
    if (authenticated) {
      _isEnabled = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', true);
      return true;
    }
    
    return false;
  }
  
  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    _isEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', false);
  }
  
  /// Get biometric types as user-friendly strings
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }
  
  /// Get available biometrics as formatted string
  String getAvailableBiometricsString() {
    if (_availableTypes.isEmpty) {
      return 'No biometric authentication available';
    }
    
    return _availableTypes
        .map((type) => getBiometricTypeName(type))
        .join(', ');
  }
  
  /// Check if specific biometric type is available
  bool hasFingerprint() => _availableTypes.contains(BiometricType.fingerprint);
  bool hasFaceRecognition() => _availableTypes.contains(BiometricType.face);
  bool hasIris() => _availableTypes.contains(BiometricType.iris);
}
