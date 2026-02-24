import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/accessibility_service.dart';
import '../services/biometric_service.dart';
import '../services/voice_command_service.dart';
import '../widgets/voice_enabled_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accessibility = AccessibilityService();
  final _biometric = BiometricService();
  final _voiceCommand = VoiceCommandService();
  
  bool _biometricAvailable = false;
  bool _obscurePassword = true;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _accessibility.speak('Welcome to InkaWallet. Please log in');
    await _checkBiometricAvailability();
  }
  
  Future<void> _checkBiometricAvailability() async {
    final available = await _biometric.checkAvailability();
    setState(() => _biometricAvailable = available && _biometric.isEnabled);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (success && mounted) {
        await _accessibility.speak('Login successful. Welcome!');
        await _voiceCommand.vibrateConfirmation();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }
  
  Future<void> _biometricLogin() async {
    await _accessibility.speak('Authenticating with biometrics');
    
    final authenticated = await _biometric.authenticateForLogin();
    
    if (authenticated) {
      // In production, retrieve stored credentials securely
      // For now, use demo account
      _emailController.text = 'admin@inkawallet.com';
      _passwordController.text = 'admin123';
      await _login();
    } else {
      await _accessibility.speak('Biometric authentication failed. Please try again.');
      await _voiceCommand.vibrateError();
    }
  }
  
  Future<void> _voiceLogin() async {
    await _accessibility.speak('Voice login activated. Please say your email address');
    await _voiceCommand.vibrateShort();
    
    final loginData = await _voiceCommand.handleLoginCommand();
    
    if (loginData != null) {
      _emailController.text = loginData['email'];
      _passwordController.text = loginData['password'];
      await _login();
    }
  }
  
  void _handleVoiceCommand(Map<String, dynamic> command) async {
    final intent = command['intent'] as String;
    
    switch (intent) {
      case 'login':
        await _voiceLogin();
        break;
        
      case 'register':
        await _accessibility.speak('Opening registration');
        await _voiceCommand.vibrateNavigation();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
        break;
        
      case 'help':
        await _voiceCommand.provideHelp(screen: 'login');
        break;
        
      default:
        await _accessibility.speak('Command not recognized. Say help for available commands.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VoiceEnabledScreen(
      screenName: 'login',
      onVoiceCommand: _handleVoiceCommand,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'InkaWallet',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accessible Digital Wallet for Everyone',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Quick access buttons for accessibility
                  if (_biometricAvailable)
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: InkWell(
                        onTap: _biometricLogin,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                _biometric.hasFaceRecognition() 
                                    ? Icons.face 
                                    : Icons.fingerprint,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Quick Login',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _biometric.getAvailableBiometricsString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_biometricAvailable) const SizedBox(height: 16),
                  
                  // Voice login button
                  if (_accessibility.isVoiceControlEnabled)
                    OutlinedButton.icon(
                      onPressed: _voiceLogin,
                      icon: const Icon(Icons.mic),
                      label: const Text('Login with Voice'),
                    ),
                  if (_accessibility.isVoiceControlEnabled) const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                    onTap: () => _accessibility.speak('Email field'),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onTap: () => _accessibility.speak('Password field'),
                  ),
                  const SizedBox(height: 24),
                  
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.error != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            auth.error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Login'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () {
                      _accessibility.speak('Opening registration');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Don\'t have an account? Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
