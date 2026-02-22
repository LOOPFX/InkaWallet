class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api'; // Android emulator localhost
  static const String apiBaseUrlProduction = 'https://api.inkawallet.com';
  
  // WebSocket Configuration (for voice)
  static const String wsBaseUrl = 'ws://10.0.2.2:3000'; // Android emulator localhost
  static const String wsBaseUrlProduction = 'wss://api.inkawallet.com';
  
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
