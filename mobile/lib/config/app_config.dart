class AppConfig {
  // API Configuration - Switch between dev and production
  static const bool isProduction = false; // Change to true for production builds
  
  static const String apiBaseUrl = isProduction 
    ? 'https://inkawallet-backend.onrender.com/api'
    : 'http://10.0.2.2:3000/api'; // Android emulator localhost
  
  static const String apiBaseUrlProduction = 'https://inkawallet-backend.onrender.com/api';
  
  // WebSocket Configuration (for voice)
  static const String wsBaseUrl = isProduction
    ? 'wss://inkawallet-backend.onrender.com'
    : 'ws://10.0.2.2:3000'; // Android emulator localhost
    
  static const String wsBaseUrlProduction = 'wss://inkawallet-backend.onrender.com';
  
  // Voice WebSocket endpoint (connects to backend proxy, NOT directly to Speechmatics)
  // Backend handles Speechmatics API key securely from .env file
  static const String voiceWebSocketUrl = '$wsBaseUrl/ws/voice';
  
  // App Configuration
  static const String appName = 'InkaWallet';
  static const String defaultCurrency = 'MKW';
  static const double defaultBalance = 100000.00;
  
  // Feature Flags
  static const bool enableVoiceByDefault = true;
  static const bool enableHapticsByDefault = true;
  static const bool enableAccessibilityByDefault = true;
}
