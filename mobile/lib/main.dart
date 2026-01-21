import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/accessibility_provider.dart';
import 'providers/transaction_provider.dart';
import 'services/voice_service.dart';
import 'services/haptic_service.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/send_money_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  await StorageService.init();
  
  // Initialize services
  final voiceService = VoiceService();
  final hapticService = HapticService();
  
  // Lock portrait orientation for better accessibility
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(MyApp(
    voiceService: voiceService,
    hapticService: hapticService,
  ));
}

class MyApp extends StatelessWidget {
  final VoiceService voiceService;
  final HapticService hapticService;
  
  const MyApp({
    Key? key,
    required this.voiceService,
    required this.hapticService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AccessibilityProvider(
            voiceService: voiceService,
            hapticService: hapticService,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(),
          update: (_, auth, wallet) => wallet!..updateAuthToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, auth, transaction) => 
              transaction!..updateAuthToken(auth.token),
        ),
      ],
      child: Consumer<AccessibilityProvider>(
        builder: (context, accessibility, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: accessibility.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // Initial route
            initialRoute: '/splash',
            
            // Routes
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/send-money': (context) => const SendMoneyScreen(),
              '/history': (context) => const TransactionHistoryScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            
            // Accessibility settings
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: accessibility.textScale,
                  boldText: accessibility.boldText,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
