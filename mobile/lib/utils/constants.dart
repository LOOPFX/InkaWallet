class AppConstants {
  // App Info
  static const String appName = 'InkaWallet';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Inclusive Digital Wallet for Everyone';
  
  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator localhost
  static const String apiVersion = 'v1';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  
  static const String balanceEndpoint = '/wallet/balance';
  static const String sendMoneyEndpoint = '/transactions/send';
  static const String transactionHistoryEndpoint = '/transactions/history';
  static const String transactionDetailsEndpoint = '/transactions';
  
  static const String profileEndpoint = '/user/profile';
  static const String updateProfileEndpoint = '/user/update';
  static const String feedbackEndpoint = '/feedback';
  
  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserPhone = 'user_phone';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyInclusiveModeEnabled = 'inclusive_mode_enabled';
  static const String keyFirstLaunch = 'first_launch';
  
  // Security
  static const int pinLength = 4;
  static const int sessionTimeout = 15; // minutes
  static const int maxLoginAttempts = 3;
  static const int tokenRefreshInterval = 50; // minutes (refresh before expiry)
  
  // Transaction Limits
  static const double minTransactionAmount = 100.0;
  static const double maxTransactionAmount = 500000.0;
  static const double dailyTransactionLimit = 1000000.0;
  
  // Offline Support
  static const int maxOfflineTransactions = 50;
  static const int syncRetryInterval = 30; // seconds
  
  // Accessibility
  static const double defaultTextScale = 1.0;
  static const double minTextScale = 0.8;
  static const double maxTextScale = 2.0;
  
  // Haptic Patterns
  static const int hapticShortDuration = 50;
  static const int hapticMediumDuration = 100;
  static const int hapticLongDuration = 200;
  
  // Voice Commands
  static const List<String> voiceCommands = [
    'check balance',
    'send money',
    'view history',
    'view transactions',
    'go back',
    'go home',
    'repeat',
    'help',
  ];
  
  // External Wallet Providers
  static const List<String> externalWalletProviders = [
    'InkaWallet',
    'Mpamba',
    'Airtel Money',
    'Standard Bank',
    'National Bank',
    'FDH Bank',
  ];
  
  // Error Messages
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorUnauthorized = 'Unauthorized. Please login again.';
  static const String errorInvalidInput = 'Invalid input. Please check your data.';
  static const String errorInsufficientFunds = 'Insufficient funds for this transaction.';
  static const String errorTransactionFailed = 'Transaction failed. Please try again.';
  
  // Success Messages
  static const String successLogin = 'Login successful';
  static const String successRegister = 'Registration successful';
  static const String successTransaction = 'Transaction completed successfully';
  static const String successFeedback = 'Thank you for your feedback';
  
  // Regex Patterns
  static final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );
  
  // Speechmatics Configuration
  static const String speechmaticsApiKey = 'YOUR_SPEECHMATICS_API_KEY';
  static const String speechmaticsLanguage = 'en';
  
  // Currency
  static const String currencySymbol = 'MWK';
  static const String currencyName = 'Malawian Kwacha';
}
