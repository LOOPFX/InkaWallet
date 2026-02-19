class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api'; // Android emulator localhost
  static const String apiBaseUrlProduction = 'https://api.inkawallet.com';
  
  // Speechmatics API
  static const String speechmaticsApiKey = 'your_speechmatics_api_key';
  static const String speechmaticsBaseUrl = 'https://asr.api.speechmatics.com/v2';
  
  // App Configuration
  static const String appName = 'InkaWallet';
  static const String defaultCurrency = 'MKW';
  static const double defaultBalance = 100000.00;
  
  // Feature Flags
  static const bool enableVoiceByDefault = true;
  static const bool enableHapticsByDefault = true;
  static const bool enableAccessibilityByDefault = true;
}
